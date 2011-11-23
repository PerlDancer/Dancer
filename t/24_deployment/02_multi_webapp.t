use strict;
use warnings;
use Test::More import => ['!pass'];

BEGIN {
    use Dancer::ModuleLoader;
    plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';
    plan skip_all => "Test::TCP is needed to run this test"
      unless Dancer::ModuleLoader->load('Test::TCP' => "1.13");
    plan skip_all => "Plack is needed to run this test"
      unless Dancer::ModuleLoader->load('Plack::Builder');
}

use Dancer;
use Plack::Builder;
use LWP::UserAgent;
use HTTP::Server::Simple::PSGI;

plan tests => 400;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;

        my @apps = (
            [ app1 => '/app1'],
            [ app2 => '/app2']
        );

        my $ua = LWP::UserAgent->new();

        for(1..100){
            my $i = int(rand(@apps));   # 0 | 1
            my $j = 1 - $i;             # opposite number

            my $app             = $apps[ $i ];
            my $app_opposite    = $apps[ $j ];

            # Testing of opposite application router
            my $req = HTTP::Request->new(GET => "http://127.0.0.1:$port/$app->[0]$app->[1]");
            my $res = $ua->request($req);
            like $res->content, qr/Hello $app->[0]/, "like test of route /$app->[0]$app->[1]";
            ok $res->code == 200, "Status of route /$app->[0]$app->[1]";

            # Testing of opposite application router
            $req = HTTP::Request->new(GET => "http://127.0.0.1:$port/$app->[0]$app_opposite->[1]");
            $res = $ua->request($req);
            unlike $res->content, qr/Hello $app->[0]/, "unlike test of route /$app->[0]$app_opposite->[1]";
            ok $res->code == 404, "Status of route /$app->[0]$app_opposite->[1]";
        }
    },
    server => sub {
        my $port = shift;

        my $app1 = sub {
            my $env = shift;
            Dancer::App->set_running_app('APP1');
            get "/app1" => sub { return "Hello app1"; };
            my $request = Dancer::Request->new(env => $env);
            Dancer->dance($request);
        };

        my $app2 = sub {
            my $env = shift;
            Dancer::App->set_running_app('APP2');
            get "/app2" => sub { return "Hello app2"; };
            my $request = Dancer::Request->new(env => $env);
            Dancer->dance($request);
        };

        my $app = builder {
            mount "/app1" => builder {$app1};
            mount "/app2" => builder {$app2};
        };

        config->{routes_per_app} = 1;
        my $server = HTTP::Server::Simple::PSGI->new($port);
        $server->host("127.0.0.1");
        $server->app($app);
        $server->run;
    },
);
