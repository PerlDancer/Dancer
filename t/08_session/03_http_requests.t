use Test::More;
use strict;
use warnings;

use File::Spec;
use File::Temp 'tempdir';
my $tempdir = tempdir('Dancer.XXXXXX', DIR => File::Spec->curdir, CLEANUP => 1);

use Dancer::Config 'setting';
eval "use Test::Requires ('LWP::UserAgent')";
plan skip_all => "Test::Requires needed for this test" if $@;
eval "use Test::TCP";
plan skip_all => "Test::TCP needed for this test" if $@;
eval "use YAML";
plan skip_all => "YAML needed for this test" if $@;
 
my @clients = qw(one two three);
my @engines = qw(YAML);

if ($ENV{DANCER_TEST_MEMCACHED}) {
    push @engines, "memcached";
    setting(memcached_servers => '127.0.0.1:11211');
}
if ($ENV{DANCER_TEST_COOKIE}) {
    push @engines, "cookie";
    setting(session_cookie_key => "secret/foo*@!");
}


plan tests => 3 * scalar(@clients) * scalar(@engines) + (scalar(@engines));

foreach my $engine (@engines) {

test_tcp(
    client => sub {
        my $port = shift;

        foreach my $client (@clients) {
            my $ua = LWP::UserAgent->new;
            $ua->cookie_jar({ file => "$tempdir/.cookies.txt" });

            my $res = $ua->get("http://127.0.0.1:$port/read_session");
            like $res->content, qr/name=''/, 
            "empty session for client $client";

            $res = $ua->get("http://127.0.0.1:$port/set_session/$client");
            ok($res->is_success, "set_session for client $client");

            $res = $ua->get("http://127.0.0.1:$port/read_session");
            like $res->content, qr/name='$client'/, 
            "session looks good for client $client"; 

        }
    },
    server => sub {
        my $port = shift;

        use lib "t/lib";
        use TestApp;
        Dancer::Config->load;

        ok(setting(session => $engine), "using engine $engine");
        setting show_errors => 1;
        setting access_log => 0;
        setting environment => 'production';
        setting port => $port;
        Dancer->dance();
    },
);
}

done_testing;
