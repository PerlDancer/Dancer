use strict;
use warnings;
use Test::More import => ['!pass'];
use Dancer::Plugin::Ajax;
# GH #671

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
use Plack::Builder;
use HTTP::Server::Simple::PSGI;

plan tests => 6;

my $js_content = q[<script type="text/javascript">
    var xhr = new XMLHttpRequest();
    xhr.open( 'POST', '/foo' );
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
    xhr.send();
    </script>
];

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $url  = "http://127.0.0.1:$port/";

        my $req = HTTP::Request->new(GET => $url);
        my $ua  = LWP::UserAgent->new();

        ok my $res = $ua->request($req), 'Got GET result';
        ok $res->is_success, 'Successful';
        is $res->content, $js_content, 'Correct JS content';

        $req = HTTP::Request->new( POST => "${url}foo" );
        $req->header( 'X-Requested-With' => 'XMLHttpRequest' );

        ok( $res = $ua->request($req), 'Got POST result' );
        ok( $res->is_success, 'Successful' );
        is( $res->content, 'bar', 'Correct content' );
    },

    server => sub {
        my $port    = shift;
        my $handler = sub {
            use Dancer;

            set port => $port, server => '127.0.0.1', apphandler => 'PSGI', startup_info => 0;

            get  '/'    => sub {$js_content};
            ajax '/foo' => sub {'bar'};

            my $env     = shift;
            my $request = Dancer::Request->new( env => $env );
            Dancer->dance($request);
        };

        my $app = builder {
            mount "/" => $handler;
        };

        my $server = HTTP::Server::Simple::PSGI->new($port);
        $server->host("127.0.0.1");
        $server->app($app);
        $server->run;
    },
);

