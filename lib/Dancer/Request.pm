package Dancer::Request;

use strict;
use warnings;
use Dancer::Object;
use Dancer::Request::Upload;
use Dancer::SharedData;
use HTTP::Body;
use URI;
use URI::Escape;

use base 'Dancer::Object';
my @http_env_keys = (
    'user_agent',      'host',
    'accept_language', 'accept_charset',
    'accept_encoding', 'keep_alive',
    'connection',      'accept', 
    'accept_type',     'referer',
);
my $count = 0;

Dancer::Request->attributes(
    # query
    'env',          'path', 'method',
    'content_type', 'content_length',
    'body',         'id', 'request_uri',
    'uploads', 'headers', 'path_info',
    @http_env_keys,
);

# aliases
sub agent                 { $_[0]->user_agent }
sub remote_address        { $_[0]->{env}->{'REMOTE_ADDR'} }
sub forwarded_for_address { $_[0]->{env}->{'X_FORWARDED_FOR'} }
sub is_head               { $_[0]->{method} eq 'HEAD' }
sub is_post               { $_[0]->{method} eq 'POST' }
sub is_get                { $_[0]->{method} eq 'GET' }
sub is_put                { $_[0]->{method} eq 'PUT' }
sub is_delete             { $_[0]->{method} eq 'DELETE' }
sub header                { $_[0]->{headers}->get($_[1]) }

# public interface compat with CGI.pm objects
sub request_method { method(@_) }
sub Vars           { params(@_) }
sub input_handle   { $_[0]->{env}->{'psgi.input'} }

sub new {
    my ($class, $env) = @_;

    $env ||= {};

    my $self = {
        path           => undef,
        method         => undef,
        params         => {},
        body           => '',
        content_length => $env->{CONTENT_LENGTH} || 0,
        content_type   => $env->{CONTENT_TYPE} || '',
        env            => $env,
        id             => ++$count,
        _chunk_size    => 4096,
        _read_position => 0,
        _body_params   => undef,
        _query_params  => undef,
        _route_params  => {},
    };

    bless $self, $class;
    $self->_init();

    return $self;
}

sub to_string {
    my ($self) = @_;
    return "[#".$self->id."] ".$self->method." ".$self->path;
}

# helper for building a request object by hand
# with forced method, path and params.
sub new_for_request {
    my ($class, $method, $path, $params) = @_;
    $params ||= {};
    $method = uc($method);

    my $req =
      $class->new({%ENV, PATH_INFO => $path, REQUEST_METHOD => $method});
    $req->{params} = {%{$req->{params}}, %{$params}};

    return $req;
}

sub base {
    my $self = shift;

    my @env_names = qw(
        SERVER_NAME HTTP_HOST SERVER_PORT SCRIPT_NAME psgi.url_scheme
    );

    my ($server, $host, $port, $path, $scheme) = @{$self->{env}}{@env_names};

    $scheme ||= $self->{'env'}{'PSGI.URL_SCHEME'}; # Windows

    my $uri = URI->new;
    $uri->scheme($scheme);
    $uri->authority($host || "$server:$port");
    $uri->path($path || '/');

    return $uri->canonical;
}

sub uri_for {
    my ( $self, $part, $params, $dont_escape ) = @_;
    my $uri = $self->base;

    # Make sure there's exactly one slash between the base and the new part
    my $base = $uri->path;
    $base =~ s|/$||;
    $part =~ s|^/||;
    $uri->path("$base/$part");

    $uri->query_form($params) if $params;

    return $dont_escape ? uri_unescape( $uri->canonical ) : $uri->canonical;
}


sub params {
    my ($self, $source) = @_;
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
        die "Unknown source params \"$source\".";
    }
}

sub is_ajax {
    my $self = shift;

    return 0 unless defined $self->header('X-Requested-With');
    return 0 if $self->header('X-Requested-With') ne 'XMLHttpRequest';
    return 1;
}

# context-aware accessor for uploads
sub upload {
    my ($self, $name) = @_;
    my $res = $self->{uploads}{$name};

    return $res unless wantarray;
    return () unless defined $res;
    return (ref($res) eq 'ARRAY') ? @$res : $res;
}

# private

sub _init {
    my ($self) = @_;

    $self->_build_headers();
    $self->_build_request_env();
    $self->_build_path()      unless $self->path;
    $self->_build_method()    unless $self->method;
    $self->_build_path_info() unless $self->path_info;

    $self->{_http_body} =
      HTTP::Body->new($self->content_type, $self->content_length);
    $self->{_http_body}->cleanup(1);
    $self->_build_params();
    $self->_build_uploads unless $self->uploads;
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
    $self->{user_agent}       = $self->{env}{HTTP_USER_AGENT};
    $self->{host}             = $self->{env}{HTTP_HOST};
    $self->{accept_language}  = $self->{env}{HTTP_ACCEPT_LANGUAGE};
    $self->{accept_charset}   = $self->{env}{HTTP_ACCEPT_CHARSET};
    $self->{accept_encoding}  = $self->{env}{HTTP_ACCEPT_ENCODING};
    $self->{keep_alive}       = $self->{env}{HTTP_KEEP_ALIVE};
    $self->{connection}       = $self->{env}{HTTP_CONNECTION};
    $self->{accept}           = $self->{env}{HTTP_ACCEPT};
    $self->{accept_type}      = $self->{env}{HTTP_ACCEPT_TYPE};
    $self->{referer}          = $self->{env}{HTTP_REFERER};
    $self->{x_requested_with} = $self->{env}{HTTP_X_REQUESTED_WITH};
}

sub _build_headers {
    my ($self) = @_;
    $self->{headers} = Dancer::SharedData->headers;
}

sub _build_params {
    my ($self) = @_;

    # params may have been populated by before filters
    # _before_ we get there, so we have to save it first
    my $previous = $self->params;

    # now parse environement params...
    $self->_parse_get_params();
    $self->_parse_post_params();

    # and merge everything
    $self->{params} = {
        %$previous,
        %{$self->{_query_params}},
        %{$self->{_route_params}},
        %{$self->{_body_params}},
    };
}

# Written from PSGI specs:
# http://search.cpan.org/dist/PSGI/PSGI.pod
sub _build_path {
    my ($self) = @_;
    my $path = "";

    $path .= $self->{env}{'SCRIPT_NAME'}
      if defined $self->{env}->{'SCRIPT_NAME'};
    $path .= $self->{env}->{'PATH_INFO'}
      if defined $self->{env}->{'PATH_INFO'};

    # fallback to REQUEST_URI if nothing found
    # we have to decode it, according to PSGI specs.
    if (defined $self->{env}->{REQUEST_URI}) {
        $self->{request_uri} = $self->{env}->{REQUEST_URI};
        $path ||= $self->_url_decode($self->{request_uri});
    }

    die "Cannot resolve path" if not $path;
    $self->{path} = $path;
}

sub _build_path_info {
    my ($self) = @_;
    my $info = $self->{env}->{'PATH_INFO'};
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
    $self->{method} = $self->{env}->{REQUEST_METHOD}
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

    my $source = $self->{env}{QUERY_STRING} || '';
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
    my $remaining = $self->{env}->{CONTENT_LENGTH} - $self->{_read_position};
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
        die "Unknown error reading input: $!";
    }
}

# Taken gently from Plack::Request, thanks to Plack authors.
sub _build_uploads {
    my ($self) = @_;

    my $uploads = $self->{_http_body}->upload;
    my %uploads;

    for my $name (keys %{ $uploads }) {
        my $files = $uploads->{$name};
        $files = ref $files eq 'ARRAY' ? $files : [$files];

        my @uploads;
        for my $upload (@{ $files }) {
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
        $self->{_body_params}{$name} =  @filenames > 1 ? \@filenames : $filenames[0];
    }

    $self->{uploads} = \%uploads;
    $self->_build_params();
}

1;

__END__

=pod

=head1 NAME

Dancer::Request - interface for accessing incoming requests

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

=head1 PUBLIC INTERFACE

=head2 method()

Return the HTTP method used by the client to access the application.

=head2 path()

Return the path requested by the client.

=head2 base()

Returns an absolute URI for the base of the application

=head2 uri_for(path, params)

Constructs a URI from the base and the passed path.  If params (hashref) is
supplied, these are added to the query string of the uri.  If the base is
C<http://localhost:5000/foo>, C<< request->uri_for('/bar', { baz => 'baz' }) >>
would return C<http://localhost:5000/foo/bar?baz=baz>.

=head2 params($source)

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

=head2 content_type()

Return the content type of the request.

=head2 content_length()

Return the content length of the request.

=head2 header($name)

Return the value of the given header, if present. If the header has multiple
values, returns an the list of values if called in list context, the first one
in scalar.

=head2 body()

Return the raw body of the request, unparsed.

If you need to access the body of the request, you have to use this accessor and
should not try to read C<psgi.input> by hand. C<Dancer::Request> already did it for you
and kept the raw body untouched in there.

=head2 is_ajax()

Return true if the value of the header C<X-Requested-With> is XMLHttpRequest.

=head2 env()

Return the current environment (C<%ENV>), as a hashref.

=head2 uploads()

Returns a reference to a hash containing uploads. Values can be either a
L<Dancer::Request::Upload> object, or an arrayref of L<Dancer::Request::Upload>
objects.

=head2 HTTP environment variables

All HTTP environment variables that are in %ENV will be provided in the
Dancer::Request object through specific accessors, here are those supported:

=over 4

=item C<user_agent>

=item C<host>

=item C<accept_language>

=item C<accept_charset>

=item C<accept_encoding>

=item C<keep_alive>

=item C<connection>

=item C<accept>

=back

=head1 AUTHORS

This module has been written by Alexis Sukrieh and was mostly
inspired by L<Plack::Request>, written by Tatsuiko Miyagawa.

Tatsuiko Miyagawa also gave a hand for the PSGI interface.

=head1 LICENCE

This module is released under the same terms as Perl itself.

=head1 SEE ALSO

L<Dancer>

=cut
