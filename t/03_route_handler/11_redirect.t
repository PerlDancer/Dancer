use strict;
use warnings;
use Test::More 'no_plan', import => ['!pass'];

use Dancer ':syntax';
use Dancer::Logger;
use File::Temp qw/tempdir/;
use Dancer::Test;

my $dir = tempdir(CLEANUP => 1, TMPDIR => 1);
set appdir => $dir;
Dancer::Logger->init('File');

get '/' => sub { 'home' };
get '/bounce' => sub { redirect '/' };

response_exists [GET => '/'];
response_content_is [GET => '/'], "home"; 

response_exists [GET => '/bounce'];
response_status_is [GET => '/bounce'], 302;

response_exists [GET => '/'];
response_content_is [GET => '/'], "home"; 

get '/redirect' => sub { header 'X-Foo' => 'foo'; redirect '/'; };

my $expected_headers = [
    'Location' => 'http://localhost/',
    'Content-Type' => 'text/html',
    'X-Foo' => 'foo',
];
response_headers_include [GET => '/redirect'] => $expected_headers;

get '/redirect_querystring' => sub { redirect '/login?failed=1' };
$expected_headers = [
    'Location' => 'http://localhost/login?failed=1',
    'Content-Type' => 'text/html',
];
response_headers_include [GET => '/redirect_querystring'] => $expected_headers;

set behind_proxy => 1;
$ENV{X_FORWARDED_HOST} = "nice.host.name";
response_headers_include [GET => '/bounce'] => [Location => 'http://nice.host.name/'];

$ENV{HTTP_FORWARDED_PROTO} = "https";
response_headers_include [GET => '/bounce'] => [Location => 'https://nice.host.name/'];

$ENV{X_FORWARDED_PROTOCOL} = "ftp";  # stupid, but why not?
response_headers_include [GET => '/bounce'] => [Location => 'ftp://nice.host.name/'];


Dancer::Logger::logger->{fh}->close;
File::Temp::cleanup();
