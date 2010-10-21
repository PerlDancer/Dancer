use strict;
use warnings;

use Dancer ':syntax';
use Dancer::ModuleLoader;

use t::lib::TestUtils;
use Test::More import => ['!pass'];

plan tests => 7;

set public => path(dirname(__FILE__), 'static');
my $public = setting('public');

my $path = '/hello.foo';
my $request = fake_request(GET => $path);

Dancer::SharedData->request($request);
my $resp = Dancer::Renderer::get_file_response();
ok( defined($resp), "static file is found for $path");

my %headers = @{$resp->headers_to_array};
like($headers{'Content-Type'}, qr/text\/plain/, 
    "$path is sent as text/plain");

ok(mime_type(foo => 'text/foo'), 'mime type foo is set as text/foo');

Dancer::SharedData->request($request);
$resp = Dancer::Renderer::get_file_response();
ok( defined($resp), "static file is found for $path");

%headers = @{$resp->headers_to_array};
is_deeply(\%headers, 
    {'Content-Type' => 'text/foo'}, 
    "$path is sent as text/foo");

$path = '/hello.txt';
$request = fake_request(GET => $path);

Dancer::SharedData->request($request);
$resp = Dancer::Renderer::get_file_response();
ok( defined($resp), "static file is found for $path");
%headers = @{$resp->headers_to_array};
is_deeply(\%headers, 
    {'Content-Type' => 'text/plain'}, 
    "$path is sent as text/plain");
