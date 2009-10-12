use Dancer::Config 'setting';
use Test::More;

eval "use Test::Requires ('LWP::UserAgent')";
eval "use Test::TCP";
plan skip_all => "Test::Requires and Test::TCP are needed for this test" if $@;
 
plan tests => 4;
test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        
        my $res = $ua->get("http://127.0.0.1:$port/env");
        like $res->content, qr/PATH_INFO/;
        
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
        Dancer::Config->load;

        setting environment => 'production';
        setting port => $port;
        Dancer->dance();
    },
);
 
done_testing;
