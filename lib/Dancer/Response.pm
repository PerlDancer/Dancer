package Dancer::Response;

use strict;
use warnings;
use Carp;

use Dancer::Config 'setting';
use Scalar::Util qw/blessed/;
use Dancer::HTTP;
use HTTP::Headers;

# constructor
sub new {
    my ($class, %args) = @_;

    my $h = delete $args{headers} || [];
    my $headers = HTTP::Headers->new(@$h);

    my $self = {
        status  => 200,
        headers => $headers,
        content => "",
        pass    => 0,
        %args,
    };
    bless $self, $class;
    return $self;
}

# a singleton to store the current response
# made public so status can be checked, etc
my $CURRENT = Dancer::Response->new();

# the accessor returns a copy of the singleton
# after having purged it.
# XXX why do we need to purge it ?
sub current {
    my $cp = $CURRENT;
    $CURRENT = Dancer::Response->new();
    return $cp;
}

sub _get_object {
    my $current;
    if (blessed($_[0]) && $_[0]->isa('Dancer::Response')) {
        $current = shift;
    }else{
        $current = $CURRENT;
    }
    return $current;
}

# helpers for the route handlers
sub exists {
    my $current = _get_object(shift);
    blessed($current) && length($current->{content});
}

# this is a class method
sub set {
    my $class = shift;
    if ( blessed( $class ) ) {
        Carp::croak("you can't call 'set' on a Dancer::Response object");
    }
    $CURRENT = shift;
}

sub content {
    my $current = _get_object(shift);
    my $content = shift;
    if (defined $content) {
        $current->{content} = $content;
    }else{
        return $current->{content};
    }
}

sub status {
    my $current = _get_object(shift);;

    if (scalar @_ > 0) {
        return $current->{status} = Dancer::HTTP->status(shift);
    }
    else {
        return $current->{status};
    }
}

sub content_type {
    my $current = _get_object(shift);

    if (scalar @_ > 0) {
        $current->header('Content-Type' => shift)
    }else{
        return $current->header('Content-Type');
    }
}

sub pass {
    my $current = _get_object(shift);
    $current->{pass} = 1
}

sub has_passed {
    my $current = _get_object(shift);
    $current->{pass};
}

sub halt {
    my $current = _get_object(shift);
    my $content = shift;

    if ( blessed($content) && $content->isa('Dancer::Response') ) {
        $CURRENT = $content;
    }
    else {
        my $resp = Dancer::Response->new(content => $content);
         $CURRENT = $resp;
    }
    $CURRENT->{halted} = 1;
    return $content;
}

sub halted {
    my $current = _get_object(shift);
    $current && $current->{halted}
}

sub header {
    my $current = _get_object(shift);
    my $header = shift;

    if (@_) {
        $current->{headers}->header($header => @_);
    }
    else {
        return $current->{headers}->header($header);
    }
}

sub headers {
    my $current = _get_object(shift);
    $current->{headers}->header(@_);
}

sub headers_to_array {
    my $current = _get_object(shift);

    my $headers = [
        map {
            my $k = $_;
            map {
                my $v = $_;
                $v =~ s/^(.+)\r?\n(.*)$/$1\r\n $2/;
                ($k => $v)
            } $current->{headers}->header($_);
          } $current->{headers}->header_field_names
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


