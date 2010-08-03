use strict;
use warnings;
use Test::More 'no_plan', import => ['!pass'];

use Dancer ':syntax';
use Dancer::Logger;
use File::Temp qw/tempdir/;
use Dancer::Test;

my $dir = tempdir(CLEANUP => 1);
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
    'X-Foo' => 'foo',
    'Location' => 'http://localhost/',
    'Content-Type' => 'text/html',
];
response_headers_are_deeply [GET => '/redirect'], $expected_headers;

get '/redirect_querystring' => sub { redirect '/login?failed=1' };
$expected_headers = [
    'Location' => 'http://localhost/login?failed=1',
    'Content-Type' => 'text/html',
];
response_headers_are_deeply [GET => '/redirect_querystring'], $expected_headers;

File::Temp::cleanup();
