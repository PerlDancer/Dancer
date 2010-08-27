use strict;
use warnings;
use Test::More import => ['!pass'];

BEGIN {
    use Dancer::ModuleLoader;

    plan skip_all => "LWP::UserAgent is needed to run this tests"
      unless Dancer::ModuleLoader->load('LWP::UserAgent');
    plan skip_all => 'Test::TCP is needed to run this test'
      unless Dancer::ModuleLoader->load('Test::TCP');
    plan skip_all => 'JSON is needed to run this test'
      unless Dancer::ModuleLoader->load('JSON');
    plan skip_all => 'HTTP::Request is needed to run this test'
      unless Dancer::ModuleLoader->load('HTTP::Request');
}

plan tests => 6;

use Dancer;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $url  = "http://127.0.0.1:$port/";
        my $req  = HTTP::Request->new( GET => $url );
        $req->header( 'Content-Type' => 'application/json' );
        my $ua = LWP::UserAgent->new;
        ok my $res = $ua->request($req);
        is $res->code, 200;
        is_deeply(JSON::decode_json($res->content), {foo => 1});
    },
    server => sub {
        my $port = shift;
        load_app 't::lib::TestSerializer';
        setting access_log => 0;
        setting port       => $port;
        Dancer->dance();
    }
);

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $url  = "http://127.0.0.1:$port/blessed";
        my $req  = HTTP::Request->new( GET => $url );
        $req->header( 'Content-Type' => 'application/json' );
        my $ua = LWP::UserAgent->new;
        ok my $res = $ua->request($req);
        is $res->code, 200;
        is_deeply( JSON::decode_json( $res->content ), { request => undef } );
    },
    server => sub {
        my $port = shift;
        load_app 't::lib::TestSerializer';
        setting access_log => 0;
        setting port       => $port;
        setting engines =>
          { JSON => { allow_blessed => 1, convert_blessed => 1 } };
        Dancer->dance();
    }
);

