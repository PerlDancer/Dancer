use strict;
use warnings;
use Test::More;

use Dancer::Config 'setting';

use File::Spec;
use File::Temp 'tempdir';
my $tempdir = tempdir('Dancer.XXXXXX', DIR => File::Spec->curdir, CLEANUP => 1);

eval "use LWP::UserAgent";
plan skip_all => "LWP needed for this test" if $@;
eval "use Test::TCP";
plan skip_all => "Test::TCP needed for this test" if $@;
 
plan tests => 9;
test_tcp(
    client => sub {
        my $port = shift;

        foreach my $client qw(one two three) {
            my $ua = LWP::UserAgent->new;
            $ua->cookie_jar({ file => "$tempdir/.cookies.txt" });

            my $res = $ua->get("http://127.0.0.1:$port/cookies");
            like $res->content, qr/\$VAR1 = \{\}/, 
            "no cookies found for the client $client";

            $res = $ua->get("http://127.0.0.1:$port/set_cookie/$client/42");
            ok($res->is_success, "set_cookie for client $client");

            $res = $ua->get("http://127.0.0.1:$port/cookies");
            like $res->content, qr/'name' => '$client'/, 
            "cookie looks good for client $client"; 
        }
    },
    server => sub {
        my $port = shift;

        use lib "t/lib";
        use TestApp;
        Dancer::Config->load;

        setting environment => 'production';
        setting port => $port;
        Dancer->dance();
    },
);
 
done_testing;
