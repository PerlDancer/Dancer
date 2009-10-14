use Dancer::Config 'setting';
use Test::More;

eval "use Test::Requires ('Plack::Loader', 'LWP::UserAgent')";
eval "use Test::TCP";
plan skip_all => "Test::Requires and Test::TCP are needed for this test" if $@;


my $app = sub {
    my $env = shift;
    local *ENV = $env;
    my $cgi = CGI->new();
    Dancer->dance($cgi);
};

plan tests => 3;
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

# FIXME this blocks for some random reason, don't know why
#        $res = $ua->post("http://127.0.0.1:$port/name", { name => "xxx" });
#        like $res->content, qr/Your name: xxx/;
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
