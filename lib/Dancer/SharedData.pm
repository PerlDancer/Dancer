package Dancer::SharedData;

use strict;
use warnings;

my $vars   = {};

sub vars {$vars}

sub var {
    my ($class, $key, $value) = @_;
    $vars->{$key} = $value if (@_ == 3);
    return $vars->{$key};
}

my $request;
sub request { (@_ == 2) ? $request = $_[1] : $request }

sub reset_all {
    $vars   = {};
}

'Dancer::SharedData';
