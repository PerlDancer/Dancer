use strict;
use warnings;
use Test::More tests => 3;
use Dancer::Cookie;

my $c = Dancer::Cookie->new(
    name  => 'dancer.slot',
    value => 42
);

is(ref($c), 'Dancer::Cookie', 
    "object of class Dancer::Cookie");

is($c->to_header, 'dancer.slot=42; path=/; HttpOnly',
    "simple cookie header looks good");

my $time = 1256392307;
$c = Dancer::Cookie->new(
    name  => 'dancer.slot',
    value => 42,
    expires => $time,
);
is($c->to_header, 
    'dancer.slot=42; path=/; expires=Sat, 24-Oct-2009 13:51:47 GMT; HttpOnly',
    "header with expires looks good");
