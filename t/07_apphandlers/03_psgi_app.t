use Test::More;
use strict;
use warnings;
use Dancer::Config 'setting';
use Dancer::ModuleLoader;

plan skip_all => "Plack is needed to run this test"
    unless Dancer::ModuleLoader->load('Plack::Loader');
plan skip_all => "LWP is needed to run this test"
    unless Dancer::ModuleLoader->load('LWP::UserAgent');
plan skip_all => "Test::TCP is needed to run this test"
    unless Dancer::ModuleLoader->load('Test::TCP');

my $app = sub {
    my $env = shift;
    my $request = Dancer::Request->new($env);
    Dancer->dance($request);
};

plan tests => 3;
Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        
        my $res = $ua->get("http://127.0.0.1:$port/env");
        like $res->content, qr/psgi\.version/, 
            'content looks good for /env';
        
        $res = $ua->get("http://127.0.0.1:$port/name/bar");
        like $res->content, qr/Your name: bar/,
            'content looks good for /name/bar';

        $res = $ua->get("http://127.0.0.1:$port/name/baz");
        like $res->content, qr/Your name: baz/,
            'content looks good for /name/baz';
    },
    server => sub {
        my $port = shift;

        use t::lib::TestApp;

        setting apphandler  => 'PSGI';
        setting environment => 'production';
        Dancer::Config->load;

        Plack::Loader->auto(port => $port)->run($app);
    },
);
