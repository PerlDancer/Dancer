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

use Dancer;
use Plack::Builder;
use LWP::UserAgent;
use HTTP::Server::Simple::PSGI;

plan tests => 100;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;

        my @apps = (qw/app1 app2/);
        my $ua = LWP::UserAgent->new();
        for(1..100){
            my $app = $apps[int(rand(scalar @apps - 1))];
            my $req = HTTP::Request->new(GET => "http://127.0.0.1:$port/$app");
            my $res = $ua->request($req);
            like $res->content, qr/Hello $app/;
        }
    },
    server => sub {
        my $port = shift;

        my $app1 = sub {
            my $env = shift;
            Dancer::App->set_running_app('APP1');
            get "/" => sub { return "Hello app1"; };
            my $request = Dancer::Request->new(env => $env);
            Dancer->dance($request);
        };

        my $app2 = sub {
            my $env = shift;
            Dancer::App->set_running_app('APP2');
            get "/" => sub { return "Hello app2"; };
            my $request = Dancer::Request->new(env => $env);
            Dancer->dance($request);
        };

        my $app = builder {
            mount "/app1" => builder {$app1};
            mount "/app2" => builder {$app2};
        };

        my $server = HTTP::Server::Simple::PSGI->new($port);
        $server->host("127.0.0.1");
        $server->app($app);
        $server->run;
    },
);
