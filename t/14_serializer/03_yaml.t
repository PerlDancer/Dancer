use strict;
use warnings;

use Test::More;
use Test::TCP;

use YAML::Syck;

use Dancer::Config 'setting';
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;

test_tcp(
    client => sub {
        my $port = shift;
        my $url  = "http://127.0.0.1:$port/";
        my $req  = HTTP::Request->new( GET => $url );
	$req->header('Content-Type' => 'text/x-yaml');
        my $res = $ua->request($req);
	my $hash = Load $res->content;
	is_deeply $hash, {foo => 1};
	$req = HTTP::Request->new(POST => $url);
	$req->header('Content-Type' => 'text/x-yaml');
	$req->content( Dump {foo => 1});
	$res = $ua->request($req);
	$hash = Load $res->content;
	is_deeply $hash, {foo => 1};
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
