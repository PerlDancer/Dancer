use strict;
use warnings;

# Test that vars are really reset between each request

use Test::More;

use LWP::UserAgent;

plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';
plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Test::TCP" => "1.30");

plan tests => 10;
Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua  = LWP::UserAgent->new;
        for (1..10) {
            my $req = HTTP::Request->new( 
                GET => "http://127.0.0.1:$port/getvarfoo"
            );
            my $res = $ua->request($req);
            is $res->content, 1;
        }
    },
    server => sub {
        my $port = shift;

        use Dancer ":tests";

        # vars should be reset before the handler is called
        var foo => 42;

        set startup_info => 0, port => $port, server => '127.0.0.1';

        get "/getvarfoo" => sub {
            return ++vars->{foo};
        };

        Dancer->dance;
    },
);
