use strict;
use warnings;

use Test::More;
use Test::TCP;

use JSON;

use Dancer::Config 'setting';
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;

test_tcp(
    client => sub {
        my $port = shift;
        my $url  = "http://127.0.0.1:$port/";
        my $req  = HTTP::Request->new( GET => $url );
	$req->header('Content-Type' => 'application/json');
        my $res = $ua->request($req);
	is_deeply JSON::decode_json $res->content, {foo => 1};
	$req = HTTP::Request->new(POST => $url);
	$req->header('Content-Type' => 'application/json');
	$req->content(JSON::encode_json({foo => 1}));
	$res = $ua->request($req);
	is_deeply JSON::decode_json $res->content, {foo => 1};
    },
    server => sub {
        my $port = shift;
        use lib "t/lib";
        use TestSerializer;
        Dancer::Config->load;
        setting port => $port;
        Dancer->dance();
    },
);

done_testing;
