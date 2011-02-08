package Dancer::Response;

use strict;
use warnings;
use Carp;

use base 'Dancer::Object';

use Dancer::Config 'setting';
use Scalar::Util qw/blessed/;
use Dancer::HTTP;
use Dancer::MIME;
use HTTP::Headers;
use Dancer::SharedData;

# constructor
sub new {
    my ( $class, %args ) = @_;

    my $h = delete $args{headers} || [];
    my $headers = HTTP::Headers->new(@$h);

    my $self = {
        status  => 200,
        headers => $headers,
        content => "",
        pass    => 0,
        halted    => 0,
        forward => "",
        %args,
    };
    bless $self, $class;

    Dancer::SharedData->response($self);

    return $self;
}

# helpers for the route handlers
sub exists {
    my $self = shift;
    return length($self->content);
}

# FIXME this whole class needs to be rewritten
sub set_current_content {
    $CURRENT->{content} = $_[0] 
        if defined $CURRENT;
}

sub content {
    my $self = shift;

    my $content = shift;
    if (defined $content) {
        $self->{content} = $content;
    }else{
        return $self->{content};
    }
}

sub status {
    my $self = shift;

    if (scalar @_ > 0) {
        return $self->{status} = Dancer::HTTP->status(shift);
    }
    else {
        return $self->{status};
    }
}

sub content_type {
    my $self = shift;

    if (scalar @_ > 0) {
        my $mimetype = Dancer::MIME->instance();
        $self->header('Content-Type' => $mimetype->mime_type_for(shift));
    }else{
        return $self->header('Content-Type');
    }
}

sub pass {
    my $self = shift;
    $self->{pass} = 1
}

sub has_passed {
    my $self = shift;
    return $self->{pass};
}

sub forward {
    my $self = shift;
    $self->{forward} = $_[0];
}

sub is_forwarded { 
    my $self = shift;
    $self->{forward};
}

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

sub headers {
    my $self = shift;
    $self->{headers}->header(@_);
}

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

1;

=head1 NAME

Dancer::Response - Response object for Dancer

=head1 SYNOPSIS

    # create a new response object
    Dancer::Response->new(
        status => 200,
        content => 'this is my content'
    );

    Dancer::Response->status; # 200

    # fetch current response object
    my $response = Dancer::Response->current;

    # fetch the current status
    $response->status; # 200

    # change the status
    $response->status(500);

=head1 PUBLIC API

=head2 new

    Dancer::Response->new(
        status  => 200,
        content => 'my content',
        headers => HTTP::Headers->new(...),
    );

create and return a new L<Dancer::Response> object

=head2 current

    my $response = Dancer::Response->current();

return the current Dancer::Response object, and reset the object

=head2 exists


    if ($response->exists) {
        ...
    }

test if the Dancer::Response object exists

=head2 set

    Dancer::Response->set(Dancer::Response->new(status=>500));

Set a new Dancer::Response object as the current response

=head2 content

    # get the content
    my $content = $response->content;
    my $content = Dancer::Response->content;

    # set the content
    $response->content('my new content');
    Dancer::Response->content('my new content');

set or get the content of the current response object

=head2 status

    # get the status
    my $status = $response->status;
    my $status = Dancer::Response->status;

    # set the status
    $response->status(201);
    Dancer::Response->status(201);

set or get the status of the current response object

=head2 content_type

    # get the status
    my $ct = $response->content_type;
    my $ct = Dancer::Response->content_type;

    # set the status
    $response->content_type('application/json');
    Dancer::Response->content_type('application/json');

set or get the status of the current response object

=head2 pass

    $response->pass;
    Dancer::Response->pass;

set the pass value to one for this response

=head2 has_passed

    if ($response->has_passed) {
        ...
    }

    if (Dancer::Response->has_passed) {
        ...
    }

test if the pass value is set to true

=head2 halt

    Dancer::Response->halt();
    $response->halt;

=head2 halted

    if (Dancer::Response->halted) {
       ...
    }

    if ($response->halted) {
        ...
    }

=head2 header

    # set the header
    $response->header('X-Foo' => 'bar');
    Dancer::Response->header('X-Foo' => 'bar');

    # get the header
    my $header = $response->header('X-Foo');
    my $header = Dancer::Response->header('X-Foo');

get or set the value of a header

=head2 headers

    $response->headers(HTTP::Headers->new(...));
    Dancer::Response->headers(HTTP::Headers->new(...));

return the list of headers for the current response

=head2 headers_to_array

    my $headers_psgi = $response->headers_to_array();
    my $headers_psgi = Dancer::Response->headers_to_array();

this method is called before returning a PSGI response. It transforms the list of headers to an array reference.


