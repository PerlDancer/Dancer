package Dancer::Deprecation;

use strict;
use warnings;
use Carp qw/croak carp/;

sub deprecated {
    my %args = @_;

    my ( $package, undef, undef, $sub ) = caller(1);

    unless ( defined $args{feature} ) {
        $args{feature} = $sub;
    }

    my $deprecated_at = defined $args{version} ? $args{version} : undef;

    my $msg;
    if ( defined $args{message} ) {
        $msg = $args{message};
    }
    else {
        $msg = "$args{feature} has been deprecated";
    }
    $msg .= " since version $deprecated_at" if defined $deprecated_at;
    $msg .= ". " . $args{reason} if defined $args{reason};

    croak($msg) if $args{fatal};
    carp($msg);
}

1;
