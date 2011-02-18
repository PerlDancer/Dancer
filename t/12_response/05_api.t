use strict;
use warnings;

use Test::More;
use Dancer::Response;

plan tests => 10;

ok my $response = Dancer::Response->new();
is $response->status, 200;

isa_ok $response->{headers}, 'HTTP::Headers';

$response->header('Content-Type' => 'text/html');
is $response->header('Content-Type'), 'text/html';

$response->status(500);
is $response->status, 500;

$response->content("this is my content");
is $response->content, "this is my content";

ok $response->exists;

$response->pass(1);
ok $response->has_passed;
$response->pass(0);
ok !$response->has_passed;

my $psgi_headers = $response->headers_to_array();
is_deeply $psgi_headers, ['Content-Type', 'text/html'];
