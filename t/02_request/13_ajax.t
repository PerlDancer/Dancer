use Test::More import => ['!pass'];
use strict;
use warnings;

plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';
plan skip_all => 'Test::TCP is needed to run this test'
    unless Dancer::ModuleLoader->load('Test::TCP' => "1.30");
plan tests => 8;

use LWP::UserAgent;
use HTTP::Headers;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;

        my $request = HTTP::Request->new(GET => "http://127.0.0.1:$port/req");
        $request->header('X-Requested-With' => 'XMLHttpRequest');
        my $res = $ua->request($request);
        ok($res->is_success, "server responded");
        is($res->content, 1, "content ok");

        $request = HTTP::Request->new(GET => "http://127.0.0.1:$port/req");
        $res = $ua->request($request);
        ok($res->is_success, "server responded");
        is($res->content, 0, "content ok");
    },
    server => sub {
        my $port = shift;
        use Dancer;
        set (port         => $port,
             server       => '127.0.0.1',
             startup_info => 0);

        get '/req' => sub {
            request->is_ajax ? return 1 : return 0;
        };
        Dancer->dance();
    },
);

# basic interface
$ENV{REQUEST_METHOD} = 'GET';
$ENV{PATH_INFO} = '/';

my $request = Dancer::Request->new(env => \%ENV);
is $request->method, 'GET';
ok !$request->is_ajax, 'no headers';

my $headers = HTTP::Headers->new('foo' => 'bar');
$request->headers($headers);
ok !$request->is_ajax, 'no requested_with headers';

$headers = HTTP::Headers->new('X-Requested-With' => 'XMLHttpRequest');
$request->headers($headers);
ok $request->is_ajax;
