use strict;
use warnings;
use Test::More tests => 2;
use Dancer::Cookie;

my $c = Dancer::Cookie->new(
    name  => 'dancer.slot',
    value => 42
);

is(ref($c), 'Dancer::Cookie', 
    "object of class Dancer::Cookie");

is($c->to_header, 'dancer.slot=42; ',
    "simple cookie header looks good");

