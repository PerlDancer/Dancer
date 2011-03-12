use strict;
use warnings;

# Test that vars are really reset between each request

use Test::More;

use LWP::UserAgent;

plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Test::TCP");

plan tests => 10;
Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua  = LWP::UserAgent->new;
        for (1..10) {
            my $req = HTTP::Request->new( GET => "http://0.0:$port/getvarfoo" );
            my $res = $ua->request($req);
            is $res->content, 1;
        }
    },
    server => sub {
        my $port = shift;

        use Dancer ":tests";

        # vars should be reset before the handler is called
        var foo => 42;

        set access_log => 0;
        set port => $port;

        get "/getvarfoo" => sub {
            return ++vars->{foo};
        };

        Dancer->dance;
    },
);
