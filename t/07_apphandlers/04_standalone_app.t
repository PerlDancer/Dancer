use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer::ModuleLoader;

plan skip_all => "LWP is needed for this test" 
    unless Dancer::ModuleLoader->load('LWP::UserAgent');
plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Test::TCP");

plan tests => 4;
Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        
        my $res = $ua->get("http://127.0.0.1:$port/env");
        like $res->content, qr/PATH_INFO/, 'path info is found in response';
        
        $res = $ua->get("http://127.0.0.1:$port/name/bar");
        like $res->content, qr/Your name: bar/, 'name is found on a GET';

        $res = $ua->get("http://127.0.0.1:$port/name/baz");
        like $res->content, qr/Your name: baz/, 'name is found on a GET';

        $res = $ua->post("http://127.0.0.1:$port/name", { name => "xxx" });
        like $res->content, qr/Your name: xxx/, 'name is found on a POST';
    },
    server => sub {
        my $port = shift;

        use Dancer;
        use t::lib::TestApp;
        Dancer::Config->load;

        setting environment => 'production';
        setting access_log => 0;
        setting port => $port;
        Dancer->dance();
    },
);
