use Test::More import => ['!pass'];

use strict;
use warnings;

use Dancer;
use lib 't';
use TestUtils;

get '/' => sub { 1 };

my @tests = (
    [ 'GET', '/', '200 OK'],
);
plan tests => scalar(@tests);

foreach my $test (@tests) {
    my ($method, $path, $expected) = @$test;
 
    my $request = fake_request($method => $path);
    Dancer::SharedData->request($request);
    my $response = Dancer::Renderer::get_action_response();

    is(Dancer::HTTP::status($response->{status}), "HTTP/1.0 $expected\r\n", 
        "status looks good for $method $path");
}

