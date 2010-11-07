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

my %tests = (
    1288817656 => "Wed, 03-Nov-2010 20:54:16 GMT",
    1288731256 => "Tue, 02-Nov-2010 20:54:16 GMT",
    1288644856 => "Mon, 01-Nov-2010 20:54:16 GMT",
    1288558456 => "Sun, 31-Oct-2010 20:54:16 GMT",
    1288472056 => "Sat, 30-Oct-2010 20:54:16 GMT",
    1288385656 => "Fri, 29-Oct-2010 20:54:16 GMT",
    1288299256 => "Thu, 28-Oct-2010 20:54:16 GMT",
    1288212856 => "Wed, 27-Oct-2010 20:54:16 GMT",
);

while(my ($time, $expected) = each %tests) {
    $c = Dancer::Cookie->new(
        name  => 'dancer.slot',
        value => 42,
        expires => $time,
    );

    is($c->to_header, 
        "dancer.slot=42; path=/; expires=$expected; HttpOnly",
        "header with expires looks good ($time)");
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
