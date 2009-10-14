use strict;
use warnings;

use lib 't';
use TestUtils;
use Test::More tests => 9, import => ['!pass'];

BEGIN {
    use_ok 'Dancer';
    use_ok 'Dancer::Config', 'setting';
}

set public => path(dirname(__FILE__), 'static');
my $public = setting('public');

my $path = '/hello.foo';
my $request = fake_request(GET => $path);

Dancer::SharedData->cgi($request);
my $resp = Dancer::Renderer::get_file_response();
ok( defined($resp), "static file is found for $path");

my %headers = @{$resp->{headers}};
like($headers{'Content-Type'}, qr/text\/plain/, 
    "$path is sent as text/plain");

ok(mime_type(foo => 'text/foo'), 'mime type foo is set as text/foo');

Dancer::SharedData->cgi($request);
$resp = Dancer::Renderer::get_file_response();
ok( defined($resp), "static file is found for $path");

%headers = @{$resp->{headers}};
is_deeply(\%headers, 
    {'Content-Type' => 'text/foo'}, 
    "$path is sent as text/foo");

$path = '/hello.txt';
$request = fake_request(GET => $path);

Dancer::SharedData->cgi($request);
$resp = Dancer::Renderer::get_file_response();
ok( defined($resp), "static file is found for $path");
%headers = @{$resp->{headers}};
is_deeply(\%headers, 
    {'Content-Type' => 'text/plain'}, 
    "$path is sent as text/plain");
