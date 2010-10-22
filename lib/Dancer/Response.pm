package Dancer::Response;

use strict;
use warnings;

use Dancer::Config 'setting';
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
my $CURRENT = Dancer::Response->new();

# the accessor returns a copy of the singleton
# after having purged it.
sub current {
    my $cp = $CURRENT;
    $CURRENT = Dancer::Response->new();
    return $cp;
}

# helpers for the route handlers
sub exists { defined $CURRENT && length($CURRENT->{content}) }
sub set { $CURRENT = shift; }
sub status { $CURRENT->{status} = Dancer::HTTP->status(shift) }
sub content_type { $CURRENT->header('Content-Type' => shift) }
sub pass { $CURRENT->{pass} = 1 }

sub halt {
    my ($class, $content) = @_;

    if (ref($content) && ref($content) eq 'Dancer::Response') {
        $CURRENT = $content;
    }
    else {
        $CURRENT = Dancer::Response->new;
        $CURRENT->{content} = $content;
    }
    $CURRENT->{halted} = 1;
    return $content;
}

sub halted { $CURRENT && $CURRENT->{halted} }

sub header {
    my $self   = shift;
    my $header = shift;

    if (@_) {
        $self->{headers}->header($header => @_);
    }
    else {
        return $self->{headers}->header($header);
    }
}

sub headers { $CURRENT->{headers}->header(@_); }

sub headers_to_array {
    my $self = shift;

    my $headers = [
        map {
            my $k = $_;
            map {
                my $v = $_;
                $v =~ s/^(.+)\r?\n(.*)$/$1\r\n $2/;
                ($k => $v)
            } $self->{headers}->header($_);
          } $self->{headers}->header_field_names
    ];

    return $headers;
}

1;

