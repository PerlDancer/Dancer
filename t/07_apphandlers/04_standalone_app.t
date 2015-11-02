use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer::ModuleLoader;

plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';
plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Test::TCP" => "1.30");
plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Plack::Loader");

use LWP::UserAgent;

plan tests => 6;

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

        # we are already skipping under MSWin32 (check plan above)
        $res = $ua->get("http://127.0.0.1:$port/issues/499/true");
        is $res->content, "OK";

        $res = $ua->get("http://127.0.0.1:$port/issues/499/false");
        is $res->content, "OK";
    },
    server => sub {
        my $port = shift;

        use Dancer;
        use File::Spec;
        use lib File::Spec->catdir( 't', 'lib' );
        use TestApp;
        Dancer::Config->load;
        set( port         => $port,
             server       => '127.0.0.1',
             startup_info => 0 );
        Dancer->dance();
    },
);
