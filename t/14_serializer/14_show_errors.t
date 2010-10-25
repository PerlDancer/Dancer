use strict;
use warnings;

use Dancer::ModuleLoader;
use Test::More import => ['!pass'];
use LWP::UserAgent;

plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Test::TCP");

plan skip_all => 'JSON is needed for this test' 
    unless Dancer::ModuleLoader->load('JSON');

plan tests => 2;


Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        my ($req, $res);

        $req = HTTP::Request->new(GET => "http://127.0.0.1:$port/with_errors");
        $res = $ua->request($req);
        like($res->content, qr{"error":"Can't locate object method \\"method\\" via package \\"UnknownPackage\\"});
        
        $req = HTTP::Request->new(GET => "http://127.0.0.1:$port/without_errors");
        $res = $ua->request($req);
        like($res->content, qr{An internal error occured});
    },

    server => sub {
        my $port = shift;

        use Dancer;
        setting port => $port;
        setting access_log => 0;
        setting serializer => 'JSON';

        get '/with_errors' => sub {
            setting show_errors => 1;
            # bam!
            UnknownPackage->method();
        };

        get '/without_errors' => sub {
            setting show_errors => 0;
            # bam!
            UnknownPackage->method();
        };

        dance;
    },
);
