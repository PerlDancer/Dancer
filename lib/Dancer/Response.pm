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
sub exists { blessed($CURRENT) && length($CURRENT->content()) }

# this is a classe method
sub set {
    my $class = shift;
    if ( blessed( $class ) ) {
        Carp::croak("you can't call 'set' on a Dancer::Response object");
    }
    $CURRENT = shift;
}

sub content {
    my $current = _get_object(shift);
    return $current->{content};
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

# XXX WTF
sub halt {
    my $current = _get_object(shift);
    my $content = shift;

    if (blessed($content) && $content->isa('Dancer::Response')) {
        $CURRENT = $content;
    }
    else {
        $CURRENT = Dancer::Response->new;
        $CURRENT->{content} = $content;
    }
    $CURRENT->{halted} = 1;
    return $content;
}

# XXX
sub halted { $CURRENT && $CURRENT->{halted} }


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

