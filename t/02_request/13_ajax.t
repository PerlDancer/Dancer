use Test::More import => ['!pass'];
use strict;
use warnings;

plan skip_all => "LWP::UserAgent is needed to run this tests"
    unless Dancer::ModuleLoader->load('LWP::UserAgent');
plan skip_all => 'Test::TCP is needed to run this test'
    unless Dancer::ModuleLoader->load('Test::TCP');
plan tests => 4;

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
        setting port => $port;
        setting access_log => 0;

        get '/req' => sub {
	    request->is_ajax ? return 1 : return 0;
        };
        Dancer->dance();
    },
);
