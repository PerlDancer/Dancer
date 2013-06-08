use strict;
use warnings;
use Test::More import => ['!pass'];

BEGIN {
    use Dancer::ModuleLoader;
    plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';
    plan skip_all => "Test::TCP is needed to run this test"
      unless Dancer::ModuleLoader->load('Test::TCP' => "1.30");
    plan skip_all => "Plack is needed to run this test"
      unless Dancer::ModuleLoader->load('Plack::Builder');
}

use HTTP::Request;
use LWP::UserAgent;

use Plack::Builder; # should be loaded in BEGIN block, but it seems that it's not the case ...
use HTTP::Server::Simple::PSGI;

plan tests => 3;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $url = "http://127.0.0.1:$port/mount/test/foo";

        my $req = HTTP::Request->new(GET => $url);
        my $ua = LWP::UserAgent->new();
        ok my $res = $ua->request($req);
        ok $res->is_success;
        is $res->content, '/foo';
    },
    server => sub {
        my $port    = shift;

        my $handler = sub {
            use Dancer;

            set port => $port, apphandler   => 'PSGI', startup_info => 0;

            get '/foo' => sub {request->path_info};

            my $env     = shift;
            my $request = Dancer::Request->new(env => $env);
            Dancer->dance($request);
        };

        my $app = builder {
            mount "/mount/test" => $handler;
        };

        my $server = HTTP::Server::Simple::PSGI->new($port);
        $server->host("127.0.0.1");
        $server->app($app);
        $server->run;
    },
);
