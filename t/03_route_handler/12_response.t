use Test::More tests => 23;

use strict;
use warnings;

use Dancer::Response;

my $r = Dancer::Response->new();
is $r->status => 200, "status looks good";
isa_ok $r->{headers} => 'HTTP::Headers';

$r->status(500);
is $r->status => 500;

Dancer::SharedData->response->status(200);
is $r->status => 200;

$r->content_type('text/plain');
is($r->content_type                           => 'text/plain');
is($r->header('Content-Type')                 => 'text/plain');
is(Dancer::SharedData->response->content_type => 'text/plain');

$r->headers('X-Bar' => 3);
is $r->header('X-Bar') => 3;

$r->header('X-Baz' => 2);
is $r->header('X-Baz') => 2;

$r->pass(1);
ok $r->has_passed;

my $headers = $r->headers_to_array;

ok $headers;
is ref $headers, 'ARRAY';
is_deeply $headers => [ 'Content-Type' => 'text/plain', 'X-Bar' => 3, 'X-Baz' => 2];

$r->content('foo');
ok $r->exists;
is $r->content => 'foo';

Dancer::SharedData->response->content('bar');
ok(Dancer::SharedData->response->exists);
is(Dancer::SharedData->response->content => 'bar');

# test for halt && halted
Dancer::Response->new(content => 'this is ok');
eval { Dancer::SharedData->response->halt('this is not ok'); };
$r = Dancer::SharedData->response();

is $r->status  => 200;
is $r->content => 'this is not ok';
is $r->halted  => 1;

Dancer::Response->new(content => 'this is ok');
eval {
    Dancer::SharedData->response->halt(Dancer::Response->new(status => 500,
                                                             content => 'this is not ok'));
};
$r = Dancer::SharedData->response();
is $r->status  => 500;
is $r->content => 'this is not ok';
is $r->halted  => 1;
