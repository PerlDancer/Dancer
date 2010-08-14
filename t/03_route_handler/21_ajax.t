use strict;
use warnings;
use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

plan skip_all => "LWP::UserAgent is needed to run this tests"
    unless Dancer::ModuleLoader->load('LWP::UserAgent');

plan skip_all => 'Test::TCP is needed to run this test'
    unless Dancer::ModuleLoader->load('Test::TCP');

plan tests => 6;

ok(Dancer::App->current->registry->is_empty, 
    "registry is empty");
ok(Dancer::Plugin::Ajax::ajax( '/', sub { "ajax" } ), "ajax helper called");
ok(!Dancer::App->current->registry->is_empty, 
    "registry is not empty");

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
        ok(!$res->is_success, "server didn't respond");
    },
    server => sub {
        my $port = shift;

        use Dancer;
        use Dancer::Plugin::Ajax;

        setting access_log => 0;
        #setting 'log' => "core";
        # setting logger => "console";
        setting port => $port;

        ajax '/req' => sub {
	     return 1;
        };
        start();
    },
);
