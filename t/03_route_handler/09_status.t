use Test::More import => ['!pass'];

use strict;
use warnings;

use Dancer ':syntax';
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;

get '/' => sub { 1 };

my @tests = (
    [ 'GET', '/', '200'],
);
plan tests => scalar(@tests);

foreach my $test (@tests) {
    my ($method, $path, $expected) = @$test;
 
    my $request = fake_request($method => $path);
    Dancer::SharedData->request($request);
    my $response = Dancer::Renderer::get_action_response();

    is(Dancer::HTTP->status($response->{status}), $expected, 
        "status looks good for $method $path");
}

