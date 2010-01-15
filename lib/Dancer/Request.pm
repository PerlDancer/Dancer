package Dancer::Request;
# webservers handling is a hell
# this class is the common gateway interface
# for getting infoirmation about the current
# request, whatever the underlying webserver.

use strict;
use warnings;
use Dancer::Object;
use Dancer::SharedData;

use base 'Dancer::Object';
Dancer::Request->attributes('path', 'method');

sub new {
    my ($class, $env) = @_;
    my $self = {
        path   => undef,
        method => undef,
        params => {},
        _input => undef,
        _chunk_size => 4096,
        _raw_body => '',
        _read_position => 0,
        _content_length => $ENV{CONTENT_LENGTH},
    };
    bless $self, $class;

    $self->_init_env($env) if defined $env;

    $self->_init();
    return $self;
}

# this is the way to ask for a hand-cooked request
sub new_for_request {
    my ($class, $method, $path, $params) = @_;
    $params ||= {};
    $method = uc($method);

    $ENV{PATH_INFO} = $path;
    $ENV{REQUEST_METHOD} = $method;
    
    my $req = $class->new;
    $req->{params} = { %{$req->{params}}, %{$params} };

    return $req;
}

sub normalize {
    my ($class, $request) = @_;

    if (ref($request) eq 'CGI') {
        return $class->new_for_request(
            $request->request_method,
            $request->path_info,
            scalar($request->Vars));
    }
    elsif (ref($request) eq $class ) {
        return $request;
    }
    else {
        die "Invalid request, unable to process the query (".ref($request).")"
    }
}

# public interface compat with CGI.pm objects
sub request_method { method(@_) }
sub path_info      { path(@_)   }
sub Vars           { params(@_) }
sub input_handle   { shift->{_input} }

sub params {
    my ($self, $name) = @_;
    return %{ $self->{params} } if wantarray && @_ == 1;
    return $self->{params} if @_ == 1;
    return $self->{params}{$name};
}

# private

sub _init_env {
    my ($self, $env) = @_;
    die "Cannot init env without a HASHREF"
        unless ref($env) eq 'HASH';
    %ENV = (%ENV, %$env);    
}

sub _init {
    my ($self) = @_;
    $self->_build_path() unless $self->path;
    $self->_build_method() unless $self->method;
    
    # input for POST/PUT data are taken from PSGI if present, 
    # fallback to STDIN
    $self->{_input} = $ENV{'psgi.input'} ? $ENV{'psgi.input'} : *STDIN;
    $self->_build_params();
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

    $path .= $ENV{'SCRIPT_NAME'} 
        if defined $ENV{'SCRIPT_NAME'};
    $path .= $ENV{'PATH_INFO'} 
        if defined $ENV{'PATH_INFO'};

    # fallback to REQUEST_URI if nothing found
    # we have to decode it, according to PSGI specs.
    $path ||= $self->_url_decode($ENV{REQUEST_URI}) 
        if defined $ENV{REQUEST_URI};

    die "Cannot resolve path" if not $path;
    $self->{path} = $path;
}

sub _build_method {
    my ($self) = @_;
    $self->{method} = $ENV{REQUEST_METHOD} || $self->{request}->request_method();
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
    $self->_parse_params($r_params, $ENV{QUERY_STRING});
}

sub _parse_post_params {
    my ($self, $r_params) = @_;

    my $body = $self->_read_to_end();
    $self->_parse_params($r_params, $body);
}

sub _parse_params {
    my ($self, $r_params, $source) = @_;
    return unless $source;
    
    foreach my $token (split /&/, $source) {
        my ($key, $val) = split(/=/, $token);
        $key = $self->_url_decode($key);
        $val = $self->_url_decode($val);
        $$r_params->{$key} = $val;
    }
    return $r_params;
}

sub _read_to_end {
    my ($self) = @_;
    
    my $content_length = $ENV{CONTENT_LENGTH} || 0;
    return unless $self->_has_something_to_read();
 
    if ($content_length > 0) {
        while (my $buffer = $self->_read() ) {
            $self->{_raw_body} .= $buffer;
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
    my ($self, ) = @_;
    my $remaining = $ENV{CONTENT_LENGTH} - $self->{_read_position};
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
