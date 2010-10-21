use Test::More tests => 8;

use strict;
use warnings;

use Dancer::Response;

my $r = Dancer::Response->new;
is $r->{status}, 200, "status looks good";

is ref(Dancer::Response->current), 'Dancer::Response', 
    "->current returned an object";
Dancer::Response::status(500);
Dancer::Response::content_type("text/plain");
Dancer::Response::headers('X-Bar' => 3);
Dancer::Response::pass();

$r = Dancer::Response->current;
is($r->{status}, 500, "status looks good");
is($r->header('content_type'), "text/plain", "content_type looks good");
is($r->{pass}, 1, "pass flag looks good");

$r->header('X-Foo' => 1, 'X-Foo' => 2);

my $headers = $r->headers_to_array;

ok $headers;
is ref $headers, 'ARRAY';
is_deeply $headers,
  [ 'Content-Type', 'text/plain', 'X-Bar', 3, 'X-Foo', 1, 'X-Foo', 2 ];

