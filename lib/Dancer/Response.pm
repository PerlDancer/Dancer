package Dancer::Response;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: Response object for Dancer
$Dancer::Response::VERSION = '1.3202';
use strict;
use warnings;
use Carp;

use base 'Dancer::Object';

use Scalar::Util qw/blessed/;
use Dancer::HTTP;
use Dancer::MIME;
use HTTP::Headers;
use Dancer::SharedData;
use Dancer::Exception qw(:all);
use Dancer::Continuation::Halted;

__PACKAGE__->attributes(qw/content pass streamed/);

# constructor
sub init {
    my ( $self, %args ) = @_;
    $self->attributes_defaults(
        status  => 200,
        content => '',
        pass    => 0,
        halted  => 0,
        forward => '',
        encoded => 0,
    );
    $self->{headers} = HTTP::Headers->new(@{ $args{headers} || [] });
    Dancer::SharedData->response($self);
}

# helpers for the route handlers
sub exists {
    my $self = shift;
    return length($self->content);
}

sub status {
    my $self = shift;

    if (scalar @_ > 0) {
        my $status = shift;
        my $numeric_status = Dancer::HTTP->status($status);
        if ($numeric_status) {
            return $self->{status} = $numeric_status;
        } else {
            carp "Unrecognised HTTP status $status";
            return;
        }
    } else {
        return $self->{status};
    }
}

sub content_type {
    my $self = shift;

    if (scalar @_ > 0) {
        my $mimetype = Dancer::MIME->instance();
        $self->header('Content-Type' => $mimetype->name_or_type(shift));
    } else {
        return $self->header('Content-Type');
    }
}

sub has_passed {
    my $self = shift;
    return $self->pass;
}

sub forward {
    my ($self, $uri, $params, $opts) = @_;
    $self->{forward} = { to_url  => $uri,
                         params  => $params,
                         options => $opts };
}

sub is_forwarded {
    my $self = shift;
    $self->{forward};
}

sub _already_encoded {
    my $self = shift;
    $self->{encoded};
}

sub halt {
    my ($self, $content) = @_;

    if ( blessed($content) && $content->isa('Dancer::Response') ) {
        $content->{halted} = 1;
        Dancer::SharedData->response($content);
    }
    else {
        $self->content($content) if defined $content;
        $self->{halted} = 1;
    }
}

sub halted {
    my $self = shift;
    return $self->{halted}
}

sub header {
    my $self   = shift;
    my $header = shift;

    if (@_) {
        $self->{headers}->header( $header => @_ );
    }
    else {
        return $self->{headers}->header($header);
    }
}

sub push_header {
    my $self   = shift;
    my $header = shift;

    if (@_) {
        foreach my $h(@_) {
            $self->{headers}->push_header( $header => $h );
        }
    }
    else {
        return $self->{headers}->header($header);
    }
}

sub headers {
    my $self = shift;
    $self->{headers}->header(@_);
}

sub headers_to_array {
    my $self = shift;

    # Time to finalise cookie headers, now
    $self->build_cookie_headers;

    my $headers = [
        map {
            my $k = $_;
            map {
                my $v = $_;
                $v =~ s/^(.+)\r?\n(.*)$/$1\r\n $2/;
                ( $k => $v )
            } $self->{headers}->header($_);
          } $self->{headers}->header_field_names
    ];

    return $headers;
}

# Given a cookie name and object, add it to the cookies we're going to send.
# Stores them in a hashref within the response object until the response is
# being built, so that, if the same cookie is set multiple times, only the last
# value given to it will appear in a Set-Cookie header.
sub add_cookie {
    my ($self, $name, $cookie) = @_;
    if ($self->{_built_cookies}) {
        die "Too late to set another cookie, headers already built";
    }
    $self->{_cookies}{$name} = $cookie;
}


# When the response is about to be rendered, that's when we build up the
# Set-Cookie headers
sub build_cookie_headers {
    my $self = shift;
    for my $name (keys %{ $self->{_cookies} }) {
        my $header = $self->{_cookies}{$name}->to_header;
        $self->push_header(
            'Set-Cookie' => $header,
        );
    }
    $self->{_built_cookies}++;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Response - Response object for Dancer

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

    # create a new response object
    Dancer::Response->new(
        status => 200,
        content => 'this is my content'
    );

    Dancer::SharedData->response->status; # 200

    # fetch current response object
    my $response = Dancer::SharedData->response;

    # fetch the current status
    $response->status; # 200

    # change the status
    $response->status(500);

=head1 PUBLIC API

=head2 new

    Dancer::Response->new(
        status  => 200,
        content => 'my content',
        headers => ['X-Foo' => 'foo-value', 'X-Bar' => 'bar-value'],
    );

create and return a new Dancer::Response object

=head2 current

    my $response = Dancer::SharedData->response->current();

return the current Dancer::Response object, and reset the object

=head2 exists

    if ($response->exists) {
        ...
    }

test if the Dancer::Response object exists

=head2 content

    # get the content
    my $content = $response->content;
    my $content = Dancer::SharedData->response->content;

    # set the content
    $response->content('my new content');
    Dancer::SharedData->response->content('my new content');

set or get the content of the current response object

=head2 status

    # get the status
    my $status = $response->status;
    my $status = Dancer::SharedData->response->status;

    # set the status
    $response->status(201);
    Dancer::SharedData->response->status(201);

Set or get the status of the current response object.  The default status is 200.

=head2 content_type

    # get the status
    my $ct = $response->content_type;
    my $ct = Dancer::SharedData->response->content_type;

    # set the status
    $response->content_type('application/json');
    Dancer::SharedData->response->content_type('application/json');

Set or get the status of the current response object.

=head2 pass

    $response->pass;
    Dancer::SharedData->response->pass;

Set the pass value to one for this response.

=head2 has_passed

    if ($response->has_passed) {
        ...
    }

    if (Dancer::SharedData->response->has_passed) {
        ...
    }

Test if the pass value is set to true.

=head2 halt($content)

    Dancer::SharedData->response->halt();
    $response->halt;

Stops the processing of the current request.  See L<Dancer/halt>.

=head2 halted

    if (Dancer::SharedData->response->halted) {
       ...
    }

    if ($response->halted) {
        ...
    }

This flag will be true if the current response has been halted.

=head2 header

    # set the header
    $response->header('X-Foo' => 'bar');
    Dancer::SharedData->response->header('X-Foo' => 'bar');

    # get the header
    my $header = $response->header('X-Foo');
    my $header = Dancer::SharedData->response->header('X-Foo');

Get or set the value of a header.

=head2 headers

    $response->headers('X-Foo' => 'fff', 'X-Bar' => 'bbb');
    Dancer::SharedData->response->headers('X-Foo' => 'fff', 'X-Bar' => 'bbb');

Return the list of headers for the current response.

=head2 headers_to_array

    my $headers_psgi = $response->headers_to_array();
    my $headers_psgi = Dancer::SharedData->response->headers_to_array();

This method is called before returning a L<< PSGI >> response. It transforms the list of headers to an array reference.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
