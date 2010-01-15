package Dancer::SharedData;

use strict;
use warnings;

my $params = {};
my $vars = {};

sub vars { $vars }
sub var { 
    my ($class, $key, $value) = @_;
    $vars->{$key} = $value if (@_ == 3);
    return $vars->{$key};
}

sub params { 
    my ($class, $value) = @_;
    $params = $value if (@_ == 2);
    return $params;
}

my $request;
sub request { (@_ == 2) ? $request = $_[1] : $request }

sub reset_all {
    $params = {};
    $vars = {};
}

'Dancer::SharedData';
