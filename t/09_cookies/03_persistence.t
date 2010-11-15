use strict;
use warnings;
use Test::More import => ['!pass'];

BEGIN {
    use Dancer::ModuleLoader;

    plan skip_all => 'Test::TCP is needed to run this test'
        unless Dancer::ModuleLoader->load('Test::TCP');
};

use LWP::UserAgent;
use Dancer;

use File::Spec;
use File::Temp 'tempdir';
my $tempdir = tempdir('Dancer.XXXXXX', DIR => File::Spec->curdir, CLEANUP => 1);

plan tests => 9;
Test::TCP::test_tcp(
    client => sub {
        my $port = shift;

        foreach my $client qw(one two three) {
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

        setting access_log => 0;
        setting environment => 'production';
        setting port => $port;
        Dancer->dance();
    },
);
