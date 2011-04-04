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
    set environment => 'production';

    get '/data' => sub {
        $data;
    };
}

use Dancer::Test;

response_exists [GET => '/data'] => "response found for /data";

response_headers_include [GET => '/data'] => [ 'Content-Type' => 'application/json' ],
  "headers have content_type set to application/json";

response_content_is [GET => '/data'] => $json, "\$data has been encoded to JSON";
