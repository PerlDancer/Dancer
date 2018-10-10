use strict;
use warnings;
use Test::More import => ['!pass'];

BEGIN {
    use Dancer::ModuleLoader;

    plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';
    plan skip_all => 'Test::TCP is needed to run this test'
        unless Dancer::ModuleLoader->load('Test::TCP' => "1.30");
};

use HTTP::Tiny::NoProxy;
use HTTP::CookieJar;
use Dancer;

use File::Spec;

plan tests => 9;
Test::TCP::test_tcp(
    client => sub {
        my $port = shift;

        foreach my $client (qw(one two three)) {
            my $ua = HTTP::Tiny::NoProxy->new(cookie_jar => HTTP::CookieJar->new);

            my $res = $ua->get("http://127.0.0.1:$port/cookies");
            like $res->{content}, qr/\$VAR1 = \{\}/,
            "no cookies found for the client $client";

            $res = $ua->get("http://127.0.0.1:$port/set_cookie/$client/42");
            # use YAML::Syck; warn Dump $res;
            ok($res->{success}, "set_cookie for client $client");

            $res = $ua->get("http://127.0.0.1:$port/cookies");
            like $res->{content}, qr/'name' => '$client'/,
            "cookie looks good for client $client";
        }
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
