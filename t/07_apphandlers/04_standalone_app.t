use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer::ModuleLoader;

plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';
plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Test::TCP" => "1.30");
plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Plack::Loader");

use HTTP::Tiny;

plan tests => 6;

my $host = '127.0.0.10';

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = HTTP::Tiny->new;

        my $res = $ua->get("http://$host:$port/env");
        like $res->{content}, qr/PATH_INFO/, 'path info is found in response';

        $res = $ua->get("http://$host:$port/name/bar");
        like $res->{content}, qr/Your name: bar/, 'name is found on a GET';

        $res = $ua->get("http://$host:$port/name/baz");
        like $res->{content}, qr/Your name: baz/, 'name is found on a GET';

        $res = $ua->post_form("http://$host:$port/name", { name => "xxx" });
        like $res->{content}, qr/Your name: xxx/, 'name is found on a POST';

        # we are already skipping under MSWin32 (check plan above)
        $res = $ua->get("http://$host:$port/issues/499/true");
        is $res->{content}, "OK";

        $res = $ua->get("http://$host:$port/issues/499/false");
        is $res->{content}, "OK";
    },
    server => sub {
        my $port = shift;

        use Dancer;
        use File::Spec;
        use lib File::Spec->catdir( 't', 'lib' );
        use TestApp;
        Dancer::Config->load;
        set( port         => $port,
             server       => '127.0.0.10',
             startup_info => 0 );
        Dancer->dance();
    },
    host => $host,
);
