use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer::ModuleLoader;

plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';
plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Test::TCP" => "1.13");
plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Plack::Loader");

use LWP::UserAgent;

plan tests => 4;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;

        my $res = $ua->get("http://127.0.0.1:$port/env");
        like $res->content, qr/PATH_INFO/, 'path info is found in response';

        $res = $ua->get("http://127.0.0.1:$port/name/bar");
        like $res->content, qr/Your name: bar/, 'name is found on a GET';

        $res = $ua->get("http://127.0.0.1:$port/name/baz");
        like $res->content, qr/Your name: baz/, 'name is found on a GET';

        $res = $ua->post("http://127.0.0.1:$port/name", { name => "xxx" });
        like $res->content, qr/Your name: xxx/, 'name is found on a POST';
    },
    server => sub {
        my $port = shift;

        use Dancer;
        use File::Spec;
        use lib File::Spec->catdir( 't', 'lib' );
        use TestApp;
        Dancer::Config->load;
        set( environment  => 'production',
             startup_info => 0,
             port         => $port,
             apphandler   => 'PSGI');
        my $app = Dancer::Handler->psgi_app;
        Plack::Loader->auto( port => $port)->run($app);
        Dancer->dance();
    },
);
