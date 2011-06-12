package Dancer::Request;
# ABSTRACT: interface for accessing incoming requests

=head1 DESCRIPTION

This class implements a common interface for accessing incoming requests in
a Dancer application.

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

=item C<user_agent>

=back

=cut

use strict;
use warnings;
use Carp;

use base 'Dancer::Object';

use Dancer::Config 'setting';
use Dancer::Request::Upload;
use Dancer::SharedData;
use Encode;
use HTTP::Body;
use URI;
use URI::Escape;

my @http_env_keys = (
                     'user_agent',
                     'accept_language',
                     'accept_charset',
                     'accept_encoding',
                     'keep_alive',
                     'connection',
                     'accept',
                     'accept_type',
                     'referer',
                     # 'host', managed manually
                    );
my $count = 0;

=method env()

Return the current environment (C<%ENV>), as a hashref.

=method path()

Return the path requested by the client.

=method method()

Return the HTTP method used by the client to access the application.

While this method returns the method string as provided by the environment, it's
better to use one of the following boolean accessors if you want to inspect the
requested method.

=method content_type()

Return the content type of the request.

=method content_length()

Return the content length of the request.

=method body()

Return the raw body of the request, unparsed.

If you need to access the body of the request, you have to use this
accessor and should not try to read C<psgi.input> by
hand. C<Dancer::Request> already did it for you and kept the raw body
untouched in there.

=method uploads()

Returns a reference to a hash containing uploads. Values can be either
a L<Dancer::Request::Upload> object, or an arrayref of
L<Dancer::Request::Upload> objects.

You should probably use the C<upload($name)> accessor instead of
manually accessing the C<uploads> hash table.

=cut

__PACKAGE__->attributes(
                        'env',
                        'path',
                        'method',
                        'content_type',
                        'content_length',
                        'body',
                        'id',
                        'uploads',
                        'headers',
                        'path_info',
                        'ajax',
                        'body_is_parsed',
                        @http_env_keys,
                       );

sub new {
    my ($self, @args) = @_;
    if (@args == 1) {
        @args = ('env' => $args[0]);
        Dancer::Deprecation->deprecated(
                      fatal   => 0,
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
sub forwarded_for_address { $_[0]->env->{'X_FORWARDED_FOR'} }


=method address()

Return the IP address of the client.

=cut
sub address {
    $_[0]->env->{REMOTE_ADDR}
}


=method host()

Set/get remote host IP.

=cut
sub host {
    if (@_==2) {
        $_[0]->{host} = $_[1];
    } else {
        my $host;
        $host = $_[0]->env->{X_FORWARDED_HOST} if setting('behind_proxy');
        $host || $_[0]->{host} || $_[0]->env->{HTTP_HOST};
    }
}

=method remote_host()

Return the remote host of the client. This only works with web servers configured
to do a reverse DNS lookup on the client's IP address.

=cut
sub remote_host {
    $_[0]->env->{REMOTE_HOST}
}

=method protocol()

Return the protocol (HTTP/1.0 or HTTP/1.1) used for the request.

=cut
sub protocol {
    $_[0]->env->{SERVER_PROTOCOL}
}

=method port()

Return the port of the server.

=cut
sub port {
    $_[0]->env->{SERVER_PORT}
}

=method request_uri()

Return the raw, undecoded request URI path.

=cut
sub request_uri {
    $_[0]->env->{REQUEST_URI}
}

=method user()

Return remote user if defined.

=cut
sub user {
    $_[0]->env->{REMOTE_USER}
}

=method script_name()

Return script_name from the environment.

=cut
sub script_name {
    $_[0]->env->{SCRIPT_NAME}
}

=method scheme()

Return the scheme of the request

=cut
sub scheme {
    my $scheme;
    if (setting('behind_proxy')) {
        $scheme = $_[0]->env->{'X_FORWARDED_PROTOCOL'}
               || $_[0]->env->{'HTTP_X_FORWARDED_PROTOCOL'}
               || $_[0]->env->{'HTTP_FORWARDED_PROTO'}
               || ""
    }
    return $scheme
        || $_[0]->env->{'psgi.url_scheme'}
        || $_[0]->env->{'PSGI.URL_SCHEME'}
        || "";
}

=method secure()

Return true of false, indicating whether the connection is secure

=cut
sub secure {
    $_[0]->scheme eq 'https'
}

=method uri()

An alias to request_uri()

=cut
sub uri                   { $_[0]->request_uri }

=method is_head()

Return true if the method requested by the client is 'HEAD'

=cut
sub is_head { $_[0]->{method} eq 'HEAD' }

=method is_post()

Return true if the method requested by the client is 'POST'

=cut
sub is_post { $_[0]->{method} eq 'POST' }

=method is_get()

Return true if the method requested by the client is 'GET'

=cut
sub is_get { $_[0]->{method} eq 'GET' }

=method is_put()

Return true if the method requested by the client is 'PUT'

=cut
sub is_put { $_[0]->{method} eq 'PUT' }

=method is_delete()

Return true if the method requested by the client is 'DELETE'

=cut
sub is_delete { $_[0]->{method} eq 'DELETE' }

=method header($name)

Return the value of the given header, if present. If the header has multiple
values, returns an the list of values if called in list context, the first one
in scalar.

=cut
sub header { $_[0]->{headers}->header($_[1]) }

=method request_method

Alias to the C<method> accessor, for backward-compatibility with C<CGI> interface.

=cut
sub request_method { method(@_) }


=method Vars

Alias to the C<params> accessor, for backward-compatibility with C<CGI> interface.

=cut
sub Vars { params(@_) }

=method input_handle

Alias to the PSGI input handle (C<< <request->env->{psgi.input}> >>)

=cut
sub input_handle { $_[0]->env->{'psgi.input'} || $_[0]->env->{'PSGI.INPUT'} }

=method new()

The constructor of the class, used internally by Dancer's core to create request
objects.

It uses the environment hash table given to build the request object:

    Dancer::Request->new(env => \%ENV);

It also accepts the C<body_is_parsed> boolean flag, if the new request object should
not parse request body.

=method init()

Used internally to define some default values and parse parameters.

=cut

sub init {
    my ($self) = @_;

    $self->{env}          ||= {};
    $self->{path}           = undef;
    $self->{method}         = undef;
    $self->{params}         = {};
    $self->{body}           = '';
    $self->{body_is_parsed} ||= 0;
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


=method to_string()

Return a string representing the request object (eg: C<"GET /some/path">)

=cut

sub to_string {
    my ($self) = @_;
    return "[#" . $self->id . "] " . $self->method . " " . $self->path;
}


=method new_for_request($method, $path, $params, $body, $headers)

An alternate constructor convienient for test scripts which creates a request
object with the arguments given.

=cut

sub new_for_request {
    my ($class, $method, $path, $params, $body, $headers) = @_;
    $params ||= {};
    $method = uc($method);

    my $req = $class->new(env => { %ENV,
                                    PATH_INFO      => $path,
                                    REQUEST_METHOD => $method});
    $req->{params}        = {%{$req->{params}}, %{$params}};
    $req->{_query_params} = $req->{params};
    $req->{body}          = $body    if defined $body;
    $req->{headers}       = $headers if $headers;

    return $req;
}


=method forward($request, $new_location_data)

Create a new request which is a clone of the current one, apart
from the path location, which points instead to the new location.
This is used internally to chain requests using the forward keyword.

Note that the new location should be a hash reference. Only one key is
required, the C<to_url>, that should point to the URL that forward
will use. Optional values are the key C<params> to a hash of
parameters to be added to the current request parameters, and the key
C<options> that points to a hash of options about the redirect (for
instance, C<method> pointing to a new request method).

=cut

sub forward {
    my ($class, $request, $to_data) = @_;

    my $env = $request->env;
    $env->{PATH_INFO} = $to_data->{to_url};

    my $new_request = $class->new(env => $env, body_is_parsed => 1);
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
    $new_request->{body}    = $request->body;
    $new_request->{headers} = $request->headers;

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

=method base()

Returns an absolute URI for the base of the application.  Returns a L<URI>
object (which stringifies to the URL, as you'd expect).

=cut
sub base {
    my $self = shift;
    my $uri  = $self->_common_uri;

    return $uri->canonical;
}

sub _common_uri {
    my $self = shift;

    my $path   = $self->env->{SCRIPT_NAME};
    my $port   = $self->env->{SERVER_PORT};
    my $server = $self->env->{SERVER_NAME};
    my $host   = $self->host;
    my $scheme = $self->scheme;

    my $uri = URI->new;
    $uri->scheme($scheme);
    $uri->authority($host || "$server:$port");
    $uri->path($path      || '/');

    return $uri;
}

=method uri_base()

Same thing as C<base> above, except it removes the last trailing slash in the
path if it is the only path.

This means that if your base is I<http://myserver/>, C<uri_base> will return
I<http://myserver> (notice no trailing slash). This is considered very useful
when using templates to do the following thing:

    <link rel="stylesheet" href="<% request.uri_base %>/css/style.css" />

=cut
sub uri_base {
    my $self  = shift;
    my $uri   = $self->_common_uri;
    my $canon = $uri->canonical;

    if ( $uri->path eq '/' ) {
        $canon =~ s{/$}{};
    }

    return $canon;
}

=method uri_for(path, params)

Constructs a URI from the base and the passed path.  If params (hashref) is
supplied, these are added to the query string of the uri.  If the base is
C<http://localhost:5000/foo>, C<< request->uri_for('/bar', { baz => 'baz' }) >>
would return C<http://localhost:5000/foo/bar?baz=baz>.  Returns a L<URI> object
(which stringifies to the URL, as you'd expect).

=cut
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


=method params($source)

Called in scalar context, returns a hashref of params, either from the specified
source (see below for more info on that) or merging all sources.

So, you can use, for instance:

    my $foo = params->{foo}

If called in list context, returns a list of key => value pairs, so you could use:

    my %allparams = params;

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

=cut
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
        croak "Unknown source params \"$source\".";
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


=method is_ajax()

Return true if the value of the header C<X-Requested-With> is XMLHttpRequest.

=cut
sub is_ajax {
    my $self = shift;

    return 0 unless defined $self->headers;
    return 0 unless defined $self->header('X-Requested-With');
    return 0 if $self->header('X-Requested-With') ne 'XMLHttpRequest';
    return 1;
}


=method upload($name)

Context-aware accessor for uploads. It's a wrapper around an access to the hash
table provided by C<uploads()>. It looks at the calling context and returns a
corresponding value.

If you have many file uploads under the same name, and call C<upload('name')> in
an array context, the accesor will unroll the ARRAY ref for you:

    my @uploads = request->upload('many_uploads'); # OK

Whereas with a manual access to the hash table, you'll end up with one element
in @uploads, being the ARRAY ref:

    my @uploads = request->uploads->{'many_uploads'};
                                       # $uploads[0]: ARRAY(0xXXXXX)

That is why this accessor should be used instead of a manual access to
C<uploads>.

=cut

sub upload {
    my ($self, $name) = @_;
    my $res = $self->{uploads}{$name};

    return $res unless wantarray;
    return ()   unless defined $res;
    return (ref($res) eq 'ARRAY') ? @$res : $res;
}



# Private!

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
    $self->{user_agent}       = $self->env->{HTTP_USER_AGENT};
    $self->{host}             = $self->env->{HTTP_HOST};
    $self->{accept_language}  = $self->env->{HTTP_ACCEPT_LANGUAGE};
    $self->{accept_charset}   = $self->env->{HTTP_ACCEPT_CHARSET};
    $self->{accept_encoding}  = $self->env->{HTTP_ACCEPT_ENCODING};
    $self->{keep_alive}       = $self->env->{HTTP_KEEP_ALIVE};
    $self->{connection}       = $self->env->{HTTP_CONNECTION};
    $self->{accept}           = $self->env->{HTTP_ACCEPT};
    $self->{accept_type}      = $self->env->{HTTP_ACCEPT_TYPE};
    $self->{referer}          = $self->env->{HTTP_REFERER};
    $self->{x_requested_with} = $self->env->{HTTP_X_REQUESTED_WITH};
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

    # now parse environement params...
    $self->_parse_get_params();
    if ($self->{body_is_parsed}) {
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

    croak "Cannot resolve path" if not $path;
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

    my $body = $self->_read_to_end();
    $self->{_body_params} = $self->{_http_body}->param;
}

sub _parse_get_params {
    my ($self) = @_;
    return $self->{_query_params} if defined $self->{_query_params};
    $self->{_query_params} = {};

    my $source = $self->env->{QUERY_STRING} || '';
    foreach my $token (split /[&;]/, $source) {
        my ($key, $val) = split(/=/, $token);
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
    my ($self) = @_;

    my $content_length = $self->content_length;
    return unless $self->_has_something_to_read();

    if ($content_length > 0) {
        while (my $buffer = $self->_read()) {
            $self->{body} .= $buffer;
            $self->{_http_body}->add($buffer);
        }
    }

    return $self->{body};
}

sub _has_something_to_read {
    my ($self) = @_;
    return 0 unless defined $self->input_handle;
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
        croak "Unknown error reading input: $!";
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




