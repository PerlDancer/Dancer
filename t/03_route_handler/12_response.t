use Test::More tests => 25;

use strict;
use warnings;

use Dancer::Response;

my $r = Dancer::Response->new();
is $r->{status}, 200, "status looks good";

is ref(Dancer::Response->current), 'Dancer::Response', 
    "->current returned an object";
Dancer::Response->status(500);
is(Dancer::Response->status, 500);

Dancer::Response->content_type("text/plain");
is(Dancer::Response->content_type, 'text/plain');

Dancer::Response->headers('X-Bar' => 3);

Dancer::Response->pass();
ok(Dancer::Response->has_passed);

$r = Dancer::Response->current;
is($r->status(), 500, "status looks good");
is($r->header('content_type'), "text/plain", "content_type looks good");
is($r->has_passed, 1, "pass flag looks good");

$r->header('X-Foo' => 1, 'X-Foo' => 2);

my $headers = $r->headers_to_array;

ok $headers;
is ref $headers, 'ARRAY';
is_deeply $headers,
  [ 'Content-Type', 'text/plain', 'X-Bar', 3, 'X-Foo', 1, 'X-Foo', 2 ];

eval { $r->set( Dancer::Response->new() ); };
ok $@;
like $@, qr/you can't call 'set' on a Dancer::Response object/;

Dancer::Response->content('foo');
ok(Dancer::Response->exists);
is(Dancer::Response->content, 'foo');

$r->content('bar');
ok($r->exists);
is($r->content, 'bar');

# test for halt && halted
Dancer::Response->new(content => 'this is ok');
Dancer::Response->halt('this is not ok');
$r = Dancer::Response->current();
is $r->status, 200;
is $r->content, 'this is not ok';
is $r->halted, 1;

Dancer::Response->new(content => 'this is ok');
Dancer::Response->halt(Dancer::Response->new(status => 500, content => 'this is not ok'));
$r = Dancer::Response->current();
is $r->status, 500;
is $r->content, 'this is not ok';
is $r->halted, 1;
                       
Dancer::Response->new(content => 'this is ok');
Dancer::Response->set($r);
is(Dancer::Response->status, 500);
is(Dancer::Response->content, 'this is not ok');
