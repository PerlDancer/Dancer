use strict;
use warnings;
use Dancer::ModuleLoader;
use Test::More import => ['!pass'];

plan skip_all => "JSON is needed for this test"
    unless Dancer::ModuleLoader->load('JSON');
plan tests => 3;

my $data = { foo => 42 };
my $json = JSON::encode_json($data);

{
    package Webservice;
    use Dancer ':syntax';

    set serializer => 'JSON';

    get '/data' => sub {
        $data;
    };
}

use t::lib::TestUtils;

my $response = get_response_for_request(GET => '/data');
ok(defined($response), "response found for /data");

is_deeply( $response->{headers}, [ 'Content-Type' => 'application/json'],
    "headers have content_type set to application/json" );

is( $response->{content}, $json,
    "\$data has been encoded to JSON");
