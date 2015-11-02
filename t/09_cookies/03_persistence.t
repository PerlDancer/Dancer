use strict;
use warnings;
use Test::More import => ['!pass'];

BEGIN {
    use Dancer::ModuleLoader;

    plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';
    plan skip_all => 'Test::TCP is needed to run this test'
        unless Dancer::ModuleLoader->load('Test::TCP' => "1.30");
    plan skip_all => "File::Temp 0.22 required"
        unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );
};

use LWP::UserAgent;
use Dancer;

use File::Spec;
my $tempdir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);

plan tests => 9;
Test::TCP::test_tcp(
    client => sub {
        my $port = shift;

        foreach my $client (qw(one two three)) {
            my $ua = LWP::UserAgent->new;
            $ua->cookie_jar({ file => "$tempdir/.cookies.txt" });

            my $res = $ua->get("http://127.0.0.1:$port/cookies");
            like $res->content, qr/\$VAR1 = \{\}/,
            "no cookies found for the client $client";

            $res = $ua->get("http://127.0.0.1:$port/set_cookie/$client/42");
            # use YAML::Syck; warn Dump $res;
            ok($res->is_success, "set_cookie for client $client");

            $res = $ua->get("http://127.0.0.1:$port/cookies");
            like $res->content, qr/'name' => '$client'/,
            "cookie looks good for client $client";
        }

        File::Temp::cleanup();
    },
    server => sub {
        my $port = shift;

        use File::Spec;
        use lib File::Spec->catdir( 't', 'lib' );
        use TestApp;
        Dancer::Config->load;

        set( startup_info => 0,
             environment  => 'production',
             port         => $port,
             server       => '127.0.0.1' );
        Dancer->dance();
    },
);
