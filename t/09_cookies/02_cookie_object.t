use strict;
use warnings;
use Test::More tests => 6;
use Dancer::Cookie;

my $c = Dancer::Cookie->new(
    name  => 'dancer.slot',
    value => 42
);

is(ref($c), 'Dancer::Cookie', 
    "object of class Dancer::Cookie");

is($c->to_header, 'dancer.slot=42; path=/; HttpOnly',
    "simple cookie header looks good");

$c = Dancer::Cookie->new(
    name => 'dancer.slot',
    value => 42,
    domain => 'http://foo.com',
);
is(
    $c->to_header,
    'dancer.slot=42; path=/; domain=http://foo.com; HttpOnly',
    "header with domain looks good"
);

$c = Dancer::Cookie->new(
    name => 'dancer.slot',
    value => 42,
    expires => 'test',
);
is(
    $c->to_header,
    'dancer.slot=42; path=/; expires=test; HttpOnly',
    "header with invalid expires looks good",
);

$c = Dancer::Cookie->new(
    name => 'msg',
    value => 'hello; world',
);
is(
    $c->to_header,
    'msg=hello%3B%20world; path=/; HttpOnly',
    "headers are uri encoded"
);


$c = Dancer::Cookie->new(
    name => 'msg',
    value => 'hello; world',
    http_only => 0,
);
is(
    $c->to_header,
    'msg=hello%3B%20world; path=/',
    "headers are uri encoded"
);
