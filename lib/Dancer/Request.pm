package Dancer::Request;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: interface for accessing incoming requests
$Dancer::Request::VERSION = '1.3202';
use strict;
use warnings;
use Carp;

use base 'Dancer::Object';

use Dancer::Config 'setting';
use Dancer::Request::Upload;
use Dancer::SharedData;
use Dancer::Session;
use Dancer::Exception qw(:all);
use Encode;
use HTTP::Body;
use URI;
use URI::Escape;

my @http_env_keys = (
    'user_agent',      'accept_language', 'accept_charset',
    'accept_encoding', 'keep_alive', 'connection',      'accept',
    'accept_type',     'referer',  #'host', managed manually
);
my $count = 0;

__PACKAGE__->attributes(

    # query
    'env',          'path',    'method',
    'content_type', 'content_length',
    'id',
    'uploads',      'headers', 'path_info',
    'ajax',         'is_forward',
    @http_env_keys,
);

sub new {
    my ($self, @args) = @_;
    if (@args == 1) {
        @args = ('env' => $args[0]);
        Dancer::Deprecation->deprecated(
                      fatal   => 1,
                      feature => 'Calling Dancer::Request->new($env)',
                      version => 1.3059,
                      reason  => 'Please use Dancer::Request->new( env => $env ) instead',
         );
    }
    $self->SUPER::new(@args);
}

# aliases
sub agent                 { $_[0]->user_agent }
sub remote_address        { $_[0]->address }
sub forwarded_for_address { $_[0]->env->{'X_FORWARDED_FOR'} || $_[0]->env->{'HTTP_X_FORWARDED_FOR'} }
sub address               { $_[0]->env->{REMOTE_ADDR} }
sub host {
    if (@_==2) {
        $_[0]->{host} = $_[1];
    } else {
        my $host;
        $host = ($_[0]->env->{X_FORWARDED_HOST} || $_[0]->env->{HTTP_X_FORWARDED_HOST}) if setting('behind_proxy');
        $host || $_[0]->{host} || $_[0]->env->{HTTP_HOST};
    }
}
sub remote_host           { $_[0]->env->{REMOTE_HOST} }
sub protocol              { $_[0]->env->{SERVER_PROTOCOL} }
sub port                  { $_[0]->env->{SERVER_PORT} }
sub request_uri           { $_[0]->env->{REQUEST_URI} }
sub user                  { $_[0]->env->{REMOTE_USER} }
sub script_name           { $_[0]->env->{SCRIPT_NAME} }
sub request_base          { $_[0]->env->{REQUEST_BASE} || $_[0]->env->{HTTP_REQUEST_BASE} }
sub scheme                {
    my $scheme;
    if (setting('behind_proxy')) {
        # PSGI specs say that X_FORWARDED_PROTO will
        # be converted into HTTP_X_FORWARDED_PROTO
        # but Dancer::Test doesn't use PSGI (for now)
        $scheme = $_[0]->env->{'X_FORWARDED_PROTOCOL'}
               || $_[0]->env->{'HTTP_X_FORWARDED_PROTOCOL'}
               || $_[0]->env->{'HTTP_X_FORWARDED_PROTO'}
               || $_[0]->env->{'HTTP_FORWARDED_PROTO'}
               || $_[0]->env->{'X_FORWARDED_PROTO'}
               || ""
    }
    return $scheme
        || $_[0]->env->{'psgi.url_scheme'}
        || $_[0]->env->{'PSGI.URL_SCHEME'}
        || "";
}
sub secure                { $_[0]->scheme eq 'https' }
sub uri                   { $_[0]->request_uri }

sub is_head               { $_[0]->{method} eq 'HEAD' }
sub is_post               { $_[0]->{method} eq 'POST' }
sub is_get                { $_[0]->{method} eq 'GET' }
sub is_put                { $_[0]->{method} eq 'PUT' }
sub is_delete             { $_[0]->{method} eq 'DELETE' }
sub is_patch              { $_[0]->{method} eq 'PATCH' }
sub header                { $_[0]->{headers}->header($_[1]) }

# We used to store the whole raw unparsed body; this was a big problem for large
# file uploads (Issue 1129).  This convenient accessor should suit the
# requirements of anyone who was fetching the request body, without having file
# uploads stored in RAM.
sub body {
    my $http_body = shift->{_http_body} or return '';
    my $body_fh = $http_body->body or return '';
    $body_fh->seek(0, 0);
    my $raw_body = join '', $body_fh->getlines;
    return $raw_body;
}

# public interface compat with CGI.pm objects
sub request_method { method(@_) }
sub Vars           { params(@_) }
sub input_handle   { $_[0]->env->{'psgi.input'} || $_[0]->env->{'PSGI.INPUT'} }

sub init {
    my ($self) = @_;

    $self->{env}          ||= {};
    $self->{path}           = undef;
    $self->{method}         = undef;
    $self->{params}         = {};
    $self->{is_forward}     ||= 0;
    $self->{content_length} = $self->env->{CONTENT_LENGTH} || 0;
    $self->{content_type}   = $self->env->{CONTENT_TYPE} || '';
    $self->{id}             = ++$count;
    $self->{_chunk_size}    = 4096;
    $self->{_read_position} = 0;
    $self->{_body_params}   = undef;
    $self->{_query_params}  = undef;
    $self->{_route_params}  = {};

    $self->_build_headers();
    $self->_build_request_env();
    $self->_build_path()      unless $self->path;
    $self->_build_path_info() unless $self->path_info;
    $self->_build_method()    unless $self->method;

    $self->{_http_body} =
      HTTP::Body->new($self->content_type, $self->content_length);
    $self->{_http_body}->cleanup(1);
    $self->_build_params();
    $self->_build_uploads unless $self->uploads;
    $self->{ajax} = $self->is_ajax;

    return $self;
}

sub to_string {
    my ($self) = @_;
    return "[#" . $self->id . "] " . $self->method . " " . $self->path;
}

# helper for building a request object by hand
# with the given method, path, params, body and headers.
sub new_for_request {
    my ($class, $method, $uri, $params, $body, $headers, $extra_env) = @_;
    $params    ||= {};
    $extra_env ||= {};
    $method = uc($method);

    my ( $path, $query_string ) = ( $uri =~ /([^?]*)(?:\?(.*))?/s ); #from HTTP::Server::Simple

    my $env = {
        %ENV,
        %{$extra_env},
        PATH_INFO      => $path,
        QUERY_STRING   => $query_string || $ENV{QUERY_STRING} || '',
        REQUEST_METHOD => $method
    };
    my $req = $class->new(env => $env);
    $req->{params}        = {%{$req->{params}}, %{$params}};
    $req->_build_params();
    $req->{_query_params} = $req->{params};
    $req->{headers}       = $headers || HTTP::Headers->new;

    # We would normally have read the request into the HTTP::Body object in
    # chunks in _read_to_end(), but here we need to do it in one hit as we were
    # passed the body to use:
    $req->{_http_body}->add($body);

    return $req;
}

#Create a new request which is a clone of the current one, apart
#from the path location, which points instead to the new location
sub forward {
    my ($class, $request, $to_data) = @_;

    my $env = $request->env;
    $env->{PATH_INFO} = $to_data->{to_url};

    my $new_request = $class->new(env => $env, is_forward => 1);
    my $new_params  = _merge_params(scalar($request->params),
                                    $to_data->{params} || {});

    if (exists($to_data->{options}{method})) {
        die unless _valid_method($to_data->{options}{method});
        $new_request->{method} = uc $to_data->{options}{method};
    }

    $new_request->{params}  = $new_params;
    $new_request->{_body_params}  = $request->{_body_params};
    $new_request->{_query_params} = $request->{_query_params};
    $new_request->{_route_params} = $request->{_route_params};
    $new_request->{_params_are_decoded} = 1;
    $new_request->{headers} = $request->headers;

    if( my $session = Dancer::Session->engine 
                      && Dancer::Session->get_current_session ) {
        my $name = $session->session_name;

        # make sure that COOKIE is populated
        $new_request->{env}{COOKIE} ||= $new_request->{env}{HTTP_COOKIE};

        no warnings;  # COOKIE can be undef
        unless ( $new_request->{env}{COOKIE} =~ /$name\s*=/ ) {
            $new_request->{env}{COOKIE} = join ';', 
                grep { $_ } 
                $new_request->{env}{COOKIE}, 
                join '=', $name, Dancer::Session->get_current_session->id;
        }
    }

    $new_request->{uploads} = $request->uploads;

    return $new_request;
}

sub _valid_method {
    my $method = shift;
    return $method =~ /^(?:head|post|get|put|delete)$/i;
}

sub _merge_params {
    my ($params, $to_add) = @_;

    die unless ref $to_add eq "HASH";
    for my $key (keys %$to_add) {
        $params->{$key} = $to_add->{$key};
    }
    return $params;
}

sub base {
    my $self = shift;
    my $uri  = $self->_common_uri;

    return $uri->canonical;
}

sub _common_uri {
    my $self = shift;

    my $path   = $self->env->{SCRIPT_NAME} || '';
    my $port   = $self->env->{SERVER_PORT};
    my $server = $self->env->{SERVER_NAME};
    my $host   = $self->host;
    my $scheme = $self->scheme;

    my $uri = URI->new;
    $uri->scheme($scheme);
    $uri->authority($host || "$server:$port");
    if (setting('behind_proxy')) {
        my $request_base = $self->env->{REQUEST_BASE} || $self->env->{HTTP_REQUEST_BASE} || '';
        $uri->path($request_base . $path || '/');
    }
    else {
        $uri->path($path || '/');
    }

    return $uri;
}

sub uri_base {
    my $self  = shift;
    my $uri   = $self->_common_uri;
    my $canon = $uri->canonical;

    if ( $uri->path eq '/' ) {
        $canon =~ s{/$}{};
    }

    return $canon;
}

sub uri_for {
    my ($self, $part, $params, $dont_escape) = @_;
    my $uri = $self->base;

    # Make sure there's exactly one slash between the base and the new part
    my $base = $uri->path;
    $base =~ s|/$||;
    $part =~ s|^/||;
    $uri->path("$base/$part");

    $uri->query_form($params) if $params;

    return $dont_escape ? uri_unescape($uri->canonical) : $uri->canonical;
}

sub params {
    my ($self, $source) = @_;

    my @caller = caller;

    if (not $self->{_params_are_decoded}) {
        $self->{params}        = _decode($self->{params});
        $self->{_body_params}  = _decode($self->{_body_params});
        $self->{_query_params} = _decode($self->{_query_params});
        $self->{_route_params} = _decode($self->{_route_params});
        $self->{_params_are_decoded} = 1;
    }

    return %{$self->{params}} if wantarray && @_ == 1;
    return $self->{params} if @_ == 1;

    if ($source eq 'query') {
        return %{$self->{_query_params}} if wantarray;
        return $self->{_query_params};
    }
    elsif ($source eq 'body') {
        return %{$self->{_body_params}} if wantarray;
        return $self->{_body_params};
    }
    if ($source eq 'route') {
        return %{$self->{_route_params}} if wantarray;
        return $self->{_route_params};
    }
    else {
        raise core_request => "Unknown source params \"$source\".";
    }
}

sub _decode {
    my ($h) = @_;
    return if not defined $h;

    if (!ref($h) && !utf8::is_utf8($h)) {
        return decode('UTF-8', $h);
    }

    if (ref($h) eq 'HASH') {
        while (my ($k, $v) = each(%$h)) {
            $h->{$k} = _decode($v);
        }
        return $h;
    }

    if (ref($h) eq 'ARRAY') {
        return [ map { _decode($_) } @$h ];
    }

    return $h;
}

sub is_ajax {
    my $self = shift;

    # when using Plack::Builder headers are not set
    # so we're checking if it's actually there with PSGI plain headers
    if ( defined $self->{x_requested_with} ) {
        if ( $self->{x_requested_with} eq "XMLHttpRequest" ) {
            return 1;
        }
    }

    return 0 unless defined $self->headers;
    return 0 unless defined $self->header('X-Requested-With');
    return 0 if $self->header('X-Requested-With') ne 'XMLHttpRequest';
    return 1;
}

# context-aware accessor for uploads
sub upload {
    my ($self, $name) = @_;
    my $res = $self->{uploads}{$name};

    return $res unless wantarray;
    return ()   unless defined $res;
    return (ref($res) eq 'ARRAY') ? @$res : $res;
}

# Some Dancer's core components sometimes need to alter
# the parsed request params, these protected accessors are provided
# for this purpose
sub _set_route_params {
    my ($self, $params) = @_;
    $self->{_route_params} = $params;
    $self->_build_params();
}

sub _set_body_params {
    my ($self, $params) = @_;
    $self->{_body_params} = $params;
    $self->_build_params();
}

sub _set_query_params {
    my ($self, $params) = @_;
    $self->{_query_params} = $params;
    $self->_build_params();
}

sub _build_request_env {
    my ($self) = @_;

   # Don't refactor that, it's called whenever a request object is needed, that
   # means at least once per request. If refactored in a loop, this will cost 4
   # times more than the following static map.
    my $env = $self->env;
    $self->{user_agent}       = $env->{HTTP_USER_AGENT};
    $self->{host}             = $env->{HTTP_HOST};
    $self->{accept_language}  = $env->{HTTP_ACCEPT_LANGUAGE};
    $self->{accept_charset}   = $env->{HTTP_ACCEPT_CHARSET};
    $self->{accept_encoding}  = $env->{HTTP_ACCEPT_ENCODING};
    $self->{keep_alive}       = $env->{HTTP_KEEP_ALIVE};
    $self->{connection}       = $env->{HTTP_CONNECTION};
    $self->{accept}           = $env->{HTTP_ACCEPT};
    $self->{accept_type}      = $env->{HTTP_ACCEPT_TYPE};
    $self->{referer}          = $env->{HTTP_REFERER};
    $self->{x_requested_with} = $env->{HTTP_X_REQUESTED_WITH};
}

sub _build_headers {
    my ($self) = @_;
    $self->{headers} = Dancer::SharedData->headers;
}

sub _build_params {
    my ($self) = @_;

    # params may have been populated by before filters
    # _before_ we get there, so we have to save it first
    my $previous = $self->{params};

    # now parse environment params...
    $self->_parse_get_params();
    if ($self->is_forward) {
        $self->{_body_params} ||= {};
    } else {
        $self->_parse_post_params();
    }

    # and merge everything
    $self->{params} = {
        %$previous,                %{$self->{_query_params}},
        %{$self->{_route_params}}, %{$self->{_body_params}},
    };

}

# Written from PSGI specs:
# http://search.cpan.org/dist/PSGI/PSGI.pod
sub _build_path {
    my ($self) = @_;
    my $path = "";

    $path .= $self->script_name if defined $self->script_name;
    $path .= $self->env->{PATH_INFO} if defined $self->env->{PATH_INFO};

    # fallback to REQUEST_URI if nothing found
    # we have to decode it, according to PSGI specs.
    if (defined $self->request_uri) {
        $path ||= $self->_url_decode($self->request_uri);
    }

    raise core_request => "Cannot resolve path" if not $path;
    $self->{path} = $path;
}

sub _build_path_info {
    my ($self) = @_;
    my $info = $self->env->{PATH_INFO};
    if (defined $info) {

        # Empty path info will be interpreted as "root".
        $info ||= '/';
    }
    else {
        $info = $self->path;
    }
    $self->{path_info} = $info;
}

sub _build_method {
    my ($self) = @_;
    $self->{method} = $self->env->{REQUEST_METHOD}
      || $self->{request}->request_method();
}

sub _url_decode {
    my ($self, $encoded) = @_;
    my $clean = $encoded;
    $clean =~ tr/\+/ /;
    $clean =~ s/%([a-fA-F0-9]{2})/pack "H2", $1/eg;
    return $clean;
}

sub _parse_post_params {
    my ($self) = @_;
    return $self->{_body_params} if defined $self->{_body_params};

    $self->_read_to_end();
    $self->{_body_params} = $self->{_http_body}->param;
}

sub _parse_get_params {
    my ($self) = @_;
    return $self->{_query_params} if defined $self->{_query_params};
    $self->{_query_params} = {};

    my $source = $self->env->{QUERY_STRING} || '';
    foreach my $token (split /[&;]/, $source) {
        my ($key, $val) = split(/=/, $token, 2);
        next unless defined $key;
        $val = (defined $val) ? $val : '';
        $key = $self->_url_decode($key);
        $val = $self->_url_decode($val);

        # looking for multi-value params
        if (exists $self->{_query_params}{$key}) {
            my $prev_val = $self->{_query_params}{$key};
            if (ref($prev_val) && ref($prev_val) eq 'ARRAY') {
                push @{$self->{_query_params}{$key}}, $val;
            }
            else {
                $self->{_query_params}{$key} = [$prev_val, $val];
            }
        }

        # simple value param (first time we see it)
        else {
            $self->{_query_params}{$key} = $val;
        }
    }
    return $self->{_query_params};
}

sub _read_to_end {
    my $self = shift;
    
    return unless $self->_has_something_to_read;

    if ( $self->content_length > 0 ) {
        my $body = '';

        while ( my $buffer = $self->_read ) {
            $self->{_http_body}->add($buffer);
        }

    }

    return $self->{_http_body};
}

sub _has_something_to_read {
    defined $_[0]->input_handle;
}

# taken from Miyagawa's Plack::Request::BodyParser
sub _read {
    my ($self,)   = @_;
    my $remaining = $self->content_length - $self->{_read_position};
    my $maxlength = $self->{_chunk_size};

    return if ($remaining <= 0);

    my $readlen = ($remaining > $maxlength) ? $maxlength : $remaining;
    my $buffer;
    my $rc;

    $rc = $self->input_handle->read($buffer, $readlen);

    if (defined $rc) {
        $self->{_read_position} += $rc;
        return $buffer;
    }
    else {
        raise core_request => "Unknown error reading input: $!";
    }
}

# Taken gently from Plack::Request, thanks to Plack authors.
sub _build_uploads {
    my ($self) = @_;

    my $uploads = _decode($self->{_http_body}->upload);
    my %uploads;

    for my $name (keys %{$uploads}) {
        my $files = $uploads->{$name};
        $files = ref $files eq 'ARRAY' ? $files : [$files];

        my @uploads;
        for my $upload (@{$files}) {
            push(
                @uploads,
                Dancer::Request::Upload->new(
                    headers  => $upload->{headers},
                    tempname => $upload->{tempname},
                    size     => $upload->{size},
                    filename => $upload->{filename},
                )
            );
        }
        $uploads{$name} = @uploads > 1 ? \@uploads : $uploads[0];

        # support access to the filename as a normal param
        my @filenames = map { $_->{filename} } @uploads;
        $self->{_body_params}{$name} =
          @filenames > 1 ? \@filenames : $filenames[0];
    }

    $self->{uploads} = \%uploads;
    $self->_build_params();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Request - interface for accessing incoming requests

=head1 VERSION

version 1.3202

=head1 DESCRIPTION

This class implements a common interface for accessing incoming requests in
a L<< Dancer >> application.

In a route handler, the current request object can be accessed by the C<request>
method, like in the following example:

    get '/foo' => sub {
        request->params; # request, params parsed as a hash ref
        request->body; # returns the request body, unparsed
        request->path; # the path requested by the client
        # ...
    };

A route handler should not read the environment by itself, but should instead
use the current request object.

=head1 PUBLIC INTERFACE

=head2 new()

The constructor of the class, used internally by Dancer's core to create request
objects.

It uses the environment hash table given to build the request object:

    Dancer::Request->new(env => \%ENV);

It also accepts the C<is_forward> boolean flag, if the new request
object is the result of a forward.

=head2 init()

Used internally to define some default values and parse parameters.

=head2 new_for_request($method, $path, $params, $body, $headers)

An alternate constructor convenient for test scripts which creates a request
object with the arguments given.

=head2 forward($request, $new_location)

Create a new request which is a clone of the current one, apart
from the path location, which points instead to the new location.
This is used internally to chain requests using the forward keyword.

Note that the new location should be a hash reference. Only one key is
required, the C<to_url>, that should point to the URL that forward
will use. Optional values are the key C<params> to a hash of
parameters to be added to the current request parameters, and the key
C<options> that points to a hash of options about the redirect (for
instance, C<method> pointing to a new request method).

=head2 is_forward

Flag that will be set to true if the request has been L<forwarded|Dancer::Request::forward>.

=head2 to_string()

Return a string representing the request object (eg: C<"GET /some/path">)

=head2 method()

Return the HTTP method used by the client to access the application.

While this method returns the method string as provided by the environment, it's
better to use one of the following boolean accessors if you want to inspect the
requested method.

=head2 address()

Return the IP address of the client.

=head2 remote_host()

Return the remote host of the client. This only works with web servers configured
to do a reverse DNS lookup on the client's IP address.

=head2 protocol()

Return the protocol (HTTP/1.0 or HTTP/1.1) used for the request.

=head2 port()

Return the port of the server.

=head2 uri()

An alias to request_uri()

=head2 request_uri()

Return the raw, undecoded request URI path.

=head2 user()

Return remote user if defined.

=head2 script_name()

Return script_name from the environment.

=head2 scheme()

Return the scheme of the request

=head2 secure()

Return true of false, indicating whether the connection is secure

=head2 is_get()

Return true if the method requested by the client is 'GET'

=head2 is_head()

Return true if the method requested by the client is 'HEAD'

=head2 is_patch()

Return true if the method requested by the client is 'PATCH'

=head2 is_post()

Return true if the method requested by the client is 'POST'

=head2 is_put()

Return true if the method requested by the client is 'PUT'

=head2 is_delete()

Return true if the method requested by the client is 'DELETE'

=head2 path()

Return the path requested by the client.

=head2 base()

Returns an absolute URI for the base of the application.  Returns a L<URI>
object (which stringifies to the URL, as you'd expect).

=head2 uri_base()

Same thing as C<base> above, except it removes the last trailing slash in the
path if it is the only path.

This means that if your base is I<http://myserver/>, C<uri_base> will return
I<http://myserver> (notice no trailing slash). This is considered very useful
when using templates to do the following thing:

    <link rel="stylesheet" href="<% request.uri_base %>/css/style.css" />

=head2 uri_for(path, params)

Constructs a URI from the base and the passed path.  If params (hashref) is
supplied, these are added to the query string of the uri.  If the base is
C<http://localhost:5000/foo>, C<< request->uri_for('/bar', { baz => 'baz' }) >>
would return C<http://localhost:5000/foo/bar?baz=baz>.  Returns a L<URI> object
(which stringifies to the URL, as you'd expect).

=head2 params($source)

Called in scalar context, returns a hashref of params, either from the specified
source (see below for more info on that) or merging all sources.

So, you can use, for instance:

    my $foo = params->{foo}

If called in list context, returns a list of key => value pairs, so you could use:

    my %allparams = params;

If the incoming form data contains multiple values for the same key, they will
be returned as an arrayref.

=head3 Fetching only params from a given source

If a required source isn't specified, a mixed hashref (or list of key value
pairs, in list context) will be returned; this will contain params from all
sources (route, query, body).

In practical terms, this means that if the param C<foo> is passed both on the
querystring and in a POST body, you can only access one of them.

If you want to see only params from a given source, you can say so by passing
the C<$source> param to C<params()>:

    my %querystring_params = params('query');
    my %route_params       = params('route');
    my %post_params        = params('body');

If source equals C<route>, then only params parsed from the route pattern
are returned.

If source equals C<query>, then only params parsed from the query string are
returned.

If source equals C<body>, then only params sent in the request body will be
returned.

If another value is given for C<$source>, then an exception is triggered.

=head2 Vars

Alias to the C<params> accessor, for backward-compatibility with C<CGI> interface.

=head2 request_method

Alias to the C<method> accessor, for backward-compatibility with C<CGI> interface.

=head2 input_handle

Alias to the PSGI input handle (C<< <request->env->{psgi.input}> >>)

=head2 content_type()

Return the content type of the request.

=head2 content_length()

Return the content length of the request.

=head2 header($name)

Return the value of the given header, if present. If the header has multiple
values, returns an the list of values if called in list context, the first one
in scalar.

=head2 headers()

Returns the L<HTTP::Header> object used to store all the headers.

=head2 body()

Return the raw body of the request, unparsed.

If you need to access the body of the request, you have to use this accessor and
should not try to read C<psgi.input> by hand. C<Dancer::Request> already did it for you
and kept the raw body untouched in there.

=head2 is_ajax()

Return true if the value of the header C<X-Requested-With> is XMLHttpRequest.

=head2 env()

Return the current environment as a hashref.

Note that a request's environment is not always reflected by the global
variable C<%ENV> (e.g., when running via L<Plack::Handler::FCGI>). In
consequence, it is recommended to always rely on the values returned by
C<env()>, and not to access C<%ENV> directly.

=head2 uploads()

Returns a reference to a hash containing uploads. Values can be either a
L<Dancer::Request::Upload> object, or an arrayref of L<Dancer::Request::Upload>
objects.

You should probably use the C<upload($name)> accessor instead of manually accessing the
C<uploads> hash table.

=head2 upload($name)

Context-aware accessor for uploads. It's a wrapper around an access to the hash
table provided by C<uploads()>. It looks at the calling context and returns a
corresponding value.

If you have many file uploads under the same name, and call C<upload('name')> in
an array context, the accessor will unroll the ARRAY ref for you:

    my @uploads = request->upload('many_uploads'); # OK

Whereas with a manual access to the hash table, you'll end up with one element
in @uploads, being the ARRAY ref:

    my @uploads = request->uploads->{'many_uploads'}; # $uploads[0]: ARRAY(0xXXXXX)

That is why this accessor should be used instead of a manual access to
C<uploads>.

=head1 Values

Given a request to http://perldancer.org:5000/request-methods?a=1 these are
the values returned by the various request->  method calls:

  base         http://perldancer.org:5000/
  host         perldancer.org
  uri_base     http://perldancer.org:5000
  uri          /request-methods?a=1
  request_uri  /request-methods?a=1
  path         /request-methods
  path_info    /request-methods
  method       GET
  port         5000
  protocol     HTTP/1.1
  scheme       http

=head1 HTTP environment variables

All HTTP environment variables that are in %ENV will be provided in the
Dancer::Request object through specific accessors, here are those supported:

=over 4

=item C<accept>

=item C<accept_charset>

=item C<accept_encoding>

=item C<accept_language>

=item C<accept_type>

=item C<agent> (alias for C<user_agent>)

=item C<connection>

=item C<forwarded_for_address>

=item C<forwarded_protocol>

=item C<forwarded_host>

=item C<host>

=item C<keep_alive>

=item C<path_info>

=item C<referer>

=item C<remote_address>

=item C<request_base>

=item C<user_agent>

=back

=head1 AUTHORS

This module has been written by Alexis Sukrieh and was mostly
inspired by L<Plack::Request>, written by Tatsuiko Miyagawa.

Tatsuiko Miyagawa also gave a hand for the PSGI interface.

=head1 LICENCE

This module is released under the same terms as Perl itself.

=head1 SEE ALSO

L<Dancer>

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
