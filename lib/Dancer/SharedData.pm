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

my $cgi;
sub cgi { (@_ == 2) ? $cgi = $_[1] : $cgi }

'Dancer::SharedData';
