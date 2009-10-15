use Test::More;

use Dancer::Config 'setting';
eval "use Test::Requires ('LWP::UserAgent')";
eval "use Test::TCP";
eval "use YAML";
plan skip_all => "YAML, Test::Requires and Test::TCP are needed for this test" if $@;
 
my @clients = qw(one two three);
my @engines = qw(yaml);
plan tests => 3 * scalar(@clients) * scalar(@engines);

foreach my $engine (@engines) {
test_tcp(
    client => sub {
        my $port = shift;

        foreach my $client (@clients) {
            my $ua = LWP::UserAgent->new;
            $ua->cookie_jar({ file => "$ENV{HOME}/.cookies.txt" });

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

        setting show_errors => 1;
        setting session => $engine;
        setting environment => 'production';
        setting port => $port;
        Dancer->dance();
    },
);
}

done_testing;
