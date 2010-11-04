use strict;
use warnings;
use Test::More tests => 12;
use Dancer::Cookie;

my $c = Dancer::Cookie->new(
    name  => 'dancer.slot',
    value => 42
);

is(ref($c), 'Dancer::Cookie', 
    "object of class Dancer::Cookie");

is($c->to_header, 'dancer.slot=42; path=/; HttpOnly',
    "simple cookie header looks good");

my @time = qw(
    1288817656
    1288731256
    1288644856
    1288558456
    1288472056
    1288385656
    1288299256
    1288212856
);

my @expected = (
    "Wed, 03-Nov-2010 20:54:16 GMT",
    "Tue, 02-Nov-2010 20:54:16 GMT",
    "Mon, 01-Nov-2010 20:54:16 GMT",
    "Sun, 31-Oct-2010 20:54:16 GMT",
    "Sat, 30-Oct-2010 20:54:16 GMT",
    "Fri, 29-Oct-2010 20:54:16 GMT",
    "Thu, 28-Oct-2010 20:54:16 GMT",
    "Wed, 27-Oct-2010 20:54:16 GMT",
);

for(0..$#time) {
    $c = Dancer::Cookie->new(
        name  => 'dancer.slot',
        value => 42,
        expires => $time[$_],
    );

    is($c->to_header, 
        "dancer.slot=42; path=/; expires=$expected[$_]; HttpOnly",
        "header with expires looks good ($_)");
}

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
