package Dancer::Request;

# webservers handling is a hell
# this class is the common gateway interface
# for getting information about the current
# request, whatever the underlying webserver.

use strict;
use warnings;
use Dancer::Object;
use Dancer::SharedData;
use HTTP::Body;

use base 'Dancer::Object';
Dancer::Request->attributes(

    # query
    'path',         'method',
    'content_type', 'content_length',

    # http env
    'user_agent',      'host',
    'accept_language', 'accept_charset',
    'accept_encoding', 'keep_alive',
    'connection',      'accept',
);

sub new {
    my ($class, $env) = @_;

    $env ||= {};

    my $self = {
        path           => undef,
        method         => undef,
        params         => {},
        content_length => $env->{CONTENT_LENGTH} || 0,
        content_type   => $env->{CONTENT_TYPE} || '',
        env            => $env,
        _chunk_size    => 4096,
        _raw_body      => '',
        _read_position => 0,
    };

    bless $self, $class;
    $self->_init();
    return $self;
}

sub env { $_[0]->{env} }

# this is the way to ask for a hand-cooked request
sub new_for_request {
    my ($class, $method, $path, $params) = @_;
    $params ||= {};
    $method = uc($method);

    my $req = $class->new({ PATH_INFO => $path, REQUEST_METHOD => $method });
    $req->{params} = {%{$req->{params}}, %{$params}};

    return $req;
}

# public interface compat with CGI.pm objects
sub request_method { method(@_) }
sub path_info      { path(@_) }
sub Vars           { params(@_) }
sub input_handle   { $_[0]->{env}->{'psgi.input'} }

sub params {
    my ($self, $name) = @_;
    return %{$self->{params}} if wantarray && @_ == 1;
    return $self->{params} if @_ == 1;
    return $self->{params}{$name};
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
    my $params = {};

    $self->_parse_get_params(\$params);
    $self->_parse_post_params(\$params)
      if defined $self->input_handle;
    $self->{params} = $params;
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

sub _parse_get_params {
    my ($self, $r_params) = @_;
    $self->_parse_params($r_params, $self->env->{QUERY_STRING});
}

sub _parse_post_params {
    my ($self, $r_params) = @_;

    my $body        = $self->_read_to_end();
    my $body_params = $self->{_http_body}->param;
    $$r_params = {%{$$r_params}, %$body_params};
}

sub _parse_params {
    my ($self, $r_params, $source) = @_;
    return unless $source;

    foreach my $token (split /&/, $source) {
        my ($key, $val) = split(/=/, $token);
        $key = $self->_url_decode($key);
        $val = $self->_url_decode($val);

        # looking for multi-value params
        if (exists $$r_params->{$key}) {
            my $prev_val = $$r_params->{$key};
            if (ref($prev_val) && ref($prev_val) eq 'ARRAY') {
                push @{$$r_params->{$key}}, $val;
            }
            else {
                $$r_params->{$key} = [$prev_val, $val];
            }
        }

        # simple value param (first time we see it)
        else {
            $$r_params->{$key} = $val;
        }
    }
    return $r_params;
}

sub _read_to_end {
    my ($self) = @_;

    my $content_length = $self->content_length;
    return unless $self->_has_something_to_read();

    if ($content_length > 0) {
        while (my $buffer = $self->_read()) {
            $self->{_raw_body} .= $buffer;
            $self->{_http_body}->add($buffer);
        }
    }
    return $self->{_raw_body};
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

    # FIXME I didn't find a better way to check that... :/
    # if we got that error below, it's because there's nothing to read at all
    local $@;
    eval { $rc = $self->input_handle->read($buffer, $readlen) };
    return if $@;

    if (defined $rc) {
        $self->{_read_position} += $rc;
        return $buffer;
    }
    else {
        die "Unknown error reading input: $!";
    }
}

1;
