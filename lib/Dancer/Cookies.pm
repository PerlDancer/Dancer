package Dancer::Cookies;
use strict;
use warnings;

# all cookies defined by the application are store in that singleton
# this is a hashref the represent all key/value pairs to store as cookies
my $COOKIES = {};
sub cookies { $COOKIES }

1;
