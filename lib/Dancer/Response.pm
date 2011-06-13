package Dancer::Response;
# ABSTRACT: class representing a Dancer response

=head1 CORE LIBRARY

This class is part of the core, it is provided for developers only.
Dancer users should not need to read this documentation as it documents 
internal parts of the code only.

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

=cut

use strict;
use warnings;
use Carp;

use base 'Dancer::Object';

use Scalar::Util qw/blessed/;
use Dancer::HTTP;
use Dancer::MIME;
use HTTP::Headers;
use Dancer::SharedData;

=attr content

Accessor for the response's content.

    my $content = $response->content;
    $response->content('my new content');

=attr pass

Accessor for the boolean "pass" flag 

    ... if $response->pass;

=cut

__PACKAGE__->attributes(qw/content pass/);

=method init

This method is called whenever a new object is created.

    Dancer::Response->new(
        status  => 200,
        content => 'my content',
        headers => HTTP::Headers->new(...),
    );

It initializes the object with sane default values and saves the object in
L<Dancer::SharedData>.

=cut

# TODO : we should stop having Dancer::SharedData here, it's a design issue
# that needs some love.
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

=method exists

Test if the Dancer::Response contains a non-null content.

    if ($response->exists) {
        ...
    }

=cut

# TODO: should be renamed has_content
sub exists {
    my $self = shift;
    return length($self->content);
}

=method status

Set or get the status of the current response object

    my $status = $response->status;
    $response->status(201);

=cut

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

=attr content_type

Accessor for the content type of the response.

    my $ct = $response->content_type;
    $response->content_type('application/json');

=cut

sub content_type {
    my $self = shift;

    if (scalar @_ > 0) {
        my $mimetype = Dancer::MIME->instance();
        $self->header('Content-Type' => $mimetype->name_or_type(shift));
    } else {
        return $self->header('Content-Type');
    }
}

=method has_passed

Syntactic sugar over the C<pass> boolean flag.

=cut

sub has_passed {
    my $self = shift;
    return $self->pass;
}

=method forward 

Register a forward destination for the current response.

=cut

sub forward {
    my ($self, $uri, $params, $opts) = @_;
    $self->{forward} = { to_url  => $uri,
                         params  => $params,
                         options => $opts };
}

=method is_forwarded

Boolean flag that tells if the response is forwarded or not.

=cut

sub is_forwarded {
    my $self = shift;
    $self->{forward};
}

=method halt

Flags the response with the C<halt> flag. This flag is used in the upper layers
of the core to know if the rendering flow should stop here or not.

This method can be passed either a L<Dancer::Response> object or a string
representing the content of the response (it will then be coerced as a 
L<Dancer::Response> object transparently).

    $response->halt($response);

=cut

sub halt {
    my ($self, $content) = @_;

    if ( blessed($content) && $content->isa('Dancer::Response') ) {
        $content->{halted} = 1;
        Dancer::SharedData->response($content);
    }
    else {
        Dancer::Response->new(
            status => ($self->status || 200),
            content => $content,
            halted => 1,
        );
    }
    return $content;
}

=method halted

Syntactic sugar over the boolean C<halted> flag.

=cut

sub halted {
    my $self = shift;
    return $self->{halted}
}

=method header

Get or set the value of a header in the current response object.

    # set the header
    $response->header('X-Foo' => 'bar');

    # get the header
    my $header = $response->header('X-Foo');

=cut

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

=method push_header

Add a header to the current response object, but don't overrite it if it already
exists.

    my $header = $response->push_header('X-Foo' => 42);

=cut

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

=method headers

Returns the list of headers registered in the current response object, as
L<HTTP::Header> objects.

=cut

sub headers {
    my $self = shift;
    $self->{headers}->header(@_);
}

=method headers_to_array

Returns an array ref of all the registered headers of the response. The array
ref will contain only key-value pairs that are PSGI-compatible. If you need a
list of L<HTTP::Header> objects, use the C<headers> method.

=cut

sub headers_to_array {
    my $self = shift;

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

=method already_encoded

Boolean flag that tells if the response's content has already been encoded or
not. It's needed for the forward mechanism to avoid double encoding of content.

=cut

sub already_encoded {
    my $self = shift;
    $self->{encoded};
}

1;
