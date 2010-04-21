package Dancer::Response;

use strict;
use warnings;

use Dancer::Config 'setting';
use Dancer::HTTP;

# constructor
sub new {
    my ($class, %args) = @_;
    my $self = {
        status  => 200,
        headers => [],
        content => "",
        pass    => 0,
        %args,
    };
    bless $self, $class;

    $self->sanitize_headers();
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
sub exists       { defined $CURRENT && length($CURRENT->{content}) }
sub set          { $CURRENT                 = shift; }
sub status       { $CURRENT->{status}       = Dancer::HTTP->status(shift) }
sub content_type { $CURRENT->{content_type} = shift }
sub pass         { $CURRENT->{pass}         = 1 }

sub halt {
    my ($class, $content) = @_;

    $CURRENT = Dancer::Response->new;
    $CURRENT->{content} = $content;
    $CURRENT->{halted}  = 1;
    return $content;
}

sub halted { $CURRENT && $CURRENT->{halted} }

sub headers {
    push @{$CURRENT->{headers}}, @_;
    $CURRENT->sanitize_headers;
}

sub sanitize_headers {
    my ($self) = @_;

    my @headers   = @{$self->{headers}};
    my @sanitized = ();
    for (my $i = 0; $i < scalar(@headers); $i += 2) {
        my ($key, $value) = ($headers[$i], $headers[$i + 1]);

        # sanitize Location, protection from CRLF injections
        if ($key eq 'Location') {
            $value =~ s/^(.+)\r?\n(.*)$/$1\r\n $2/;
        }
        push @sanitized, ($key => $value);
    }
    $self->{headers} = \@sanitized;
}

sub update_headers {
    my ($self, %params) = @_;
    my $headers = $self->{headers};
    my @new_headers;

    for (my $i = 0; $i < scalar(@$headers); $i += 2) {
        my ($key, $value) = ($headers->[$i], $headers->[$i + 1]);
        push @new_headers, ($key => $params{$key}) if exists($params{$key});
    }
    $self->{headers} = \@new_headers;
}

1;
