package Dancer::SharedData;

use strict;
use warnings;

my $params = {};

sub params { 
    my ($class, $value) = @_;
    $params = $value if (@_ == 2);
    return $params;
}

'Dancer::SharedData';
