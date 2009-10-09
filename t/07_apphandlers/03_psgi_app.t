use Dancer::Config 'setting';
use Test::More 'no_plan';
use Test::Requires qw(Plack::Loader LWP::UserAgent);
use Test::TCP;
 
my $app = sub {
    my $env = shift;
    local *ENV = $env;
    my $cgi = CGI->new();
    Dancer->dance($cgi);
};

test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        
        my $res = $ua->get("http://127.0.0.1:$port/env");
        like $res->content, qr/psgi\.version/;
        
        $res = $ua->get("http://127.0.0.1:$port/name/bar");
        like $res->content, qr/Your name: bar/;

        $res = $ua->get("http://127.0.0.1:$port/name/baz");
        like $res->content, qr/Your name: baz/;

        $res = $ua->post("http://127.0.0.1:$port/name", { name => "xxx" });
        like $res->content, qr/Your name: xxx/;
    },
    server => sub {
        my $port = shift;

        use lib "t/lib";
        use TestApp;

        setting apphandler  => 'PSGI';
        setting environment => 'production';
        Dancer::Config->load;

        Plack::Loader->auto(port => $port)->run($app);
    },
);
 
done_testing;
