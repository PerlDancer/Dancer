package Dancer::Response;

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

__PACKAGE__->attributes(qw/content pass/);

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
        # This also sets the Response as the current one (SharedData)
        Dancer::Response->new(
            status => ($self->status || 200),
            content => $content,
            halted => 1,
        );
    }
    raise E_HALTED;
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
        headers => HTTP::Headers->new(...),
    );

create and return a new L<Dancer::Response> object

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

set or get the status of the current response object

=head2 content_type

    # get the status
    my $ct = $response->content_type;
    my $ct = Dancer::SharedData->response->content_type;

    # set the status
    $response->content_type('application/json');
    Dancer::SharedData->response->content_type('application/json');

set or get the status of the current response object

=head2 pass

    $response->pass;
    Dancer::SharedData->response->pass;

set the pass value to one for this response

=head2 has_passed

    if ($response->has_passed) {
        ...
    }

    if (Dancer::SharedData->response->has_passed) {
        ...
    }

test if the pass value is set to true

=head2 halt

    Dancer::SharedData->response->halt();
    $response->halt;

=head2 halted

    if (Dancer::SharedData->response->halted) {
       ...
    }

    if ($response->halted) {
        ...
    }

=head2 header

    # set the header
    $response->header('X-Foo' => 'bar');
    Dancer::SharedData->response->header('X-Foo' => 'bar');

    # get the header
    my $header = $response->header('X-Foo');
    my $header = Dancer::SharedData->response->header('X-Foo');

get or set the value of a header

=head2 headers

    $response->headers(HTTP::Headers->new(...));
    Dancer::SharedData->response->headers(HTTP::Headers->new(...));

return the list of headers for the current response

=head2 headers_to_array

    my $headers_psgi = $response->headers_to_array();
    my $headers_psgi = Dancer::SharedData->response->headers_to_array();

this method is called before returning a PSGI response. It transforms the list of headers to an array reference.


