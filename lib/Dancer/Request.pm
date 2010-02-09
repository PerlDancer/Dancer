package Dancer::Request;

use strict;
use warnings;
use Dancer::Object;
use Dancer::SharedData;
use HTTP::Body;

use base 'Dancer::Object';
Dancer::Request->attributes(

    # query
    'env',          'path', 'method',
    'content_type', 'content_length',
    'body',

    # http env
    'user_agent',      'host',
    'accept_language', 'accept_charset',
    'accept_encoding', 'keep_alive',
    'connection',      'accept',
    'referer',
);

# aliases
sub agent { $_[0]->user_agent }

sub remote_address {
    $_[0]->env->{'X_FORWARDED_FOR'} || $_[0]->env->{'REMOTE_ADDR'};
}

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

# public interface compat with CGI.pm objects (FIXME do Dancer's users really
# need that compat layer? ) Not sure...
sub request_method { method(@_) }
sub path_info      { path(@_) }
sub Vars           { params(@_) }
sub input_handle   { $_[0]->{env}->{'psgi.input'} }

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

# private

sub _init {
    my ($self) = @_;

    $self->_build_path()   unless $self->path;
    $self->_build_method() unless $self->method;
    $self->_build_request_env();

    $self->{_http_body} =
      HTTP::Body->new($self->content_type, $self->content_length);
    $self->_build_params();
}

sub _set_route_params {
    my ($self, $params) = @_;
    $self->{_route_params} = $params;
    $self->_build_params();
}

sub _build_request_env {
    my ($self) = @_;
    foreach my $http_env (grep /^HTTP_/, keys %{$self->env}) {
        my $key = lc $http_env;
        $key =~ s/^http_//;
        $self->{$key} = $self->env->{$http_env};
    }
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

    $path .= $self->env->{'SCRIPT_NAME'}
      if defined $self->env->{'SCRIPT_NAME'};
    $path .= $self->env->{'PATH_INFO'}
      if defined $self->env->{'PATH_INFO'};

    # fallback to REQUEST_URI if nothing found
    # we have to decode it, according to PSGI specs.
    $path ||= $self->_url_decode($self->env->{REQUEST_URI})
      if defined $self->env->{REQUEST_URI};

    die "Cannot resolve path" if not $path;
    $self->{path} = $path;
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

    my $source = $self->{env}{QUERY_STRING} || '';
    foreach my $token (split /&/, $source) {
        my ($key, $val) = split(/=/, $token);
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
    my $remaining = $self->env->{CONTENT_LENGTH} - $self->{_read_position};
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

1;

__END__

=pod

=head1 NAME

Dancer::Request 

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

A route handler should not read the environment by itslef, but should instead
use the current request object.

=head1 PUBLIC INTERFACE

=head2 method()

Return the HTTP method used by the client to access the application.

=head2 path()

Return the path requested by the client.

=head2 params($source)

If no source given, return a mixed hashref containing all the parameters that
have been parsed. 
Be aware it's a mixed structure, so if you use multiple
variables with the same name in your route pattern, query string or request
body, you can't know for sure which value you'll get there.

If you need to use the same name for different sources of input, use the
C<$source> option, like the following:

If source equals C<route>, then only params parsed from route pattern 
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

=head2 body()

Return the raw body of the request, unparsed.

If you need to access the body of the request, you have to use this accessor and
should not try to read C<psgi.input> by hand. C<Dancer::Request> already did it for you
and kept the raw body untouched in there.

=head2 env()

Return the current environement (C<%ENV>), as a hashref.

=head2 HTTP environment variables

All HTTP environement variables that are in %ENV will be provided in the
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
