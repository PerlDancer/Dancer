use strict;
use warnings;
use Test::More import => ['!pass'];

BEGIN {
    use Dancer::ModuleLoader;

    plan skip_all => 'Test::TCP is needed to run this test'
      unless Dancer::ModuleLoader->load('Test::TCP');
    plan skip_all => 'JSON is needed to run this test'
      unless Dancer::ModuleLoader->load('JSON');
}

use Dancer;
use LWP::UserAgent;
use HTTP::Request;

plan tests => 11;

my $content_types = {'JSON' => 'application/json',};

test_json();

sub test_json {
    return unless Dancer::ModuleLoader->load('JSON');
    ok(setting('serializer' => 'JSON'), "serializer JSON loaded");

    Test::TCP::test_tcp(
        client => sub {
            my $port = shift;
            my $url  = "http://127.0.0.1:$port/";
            my $req  = HTTP::Request->new(GET => $url);
            $req->header('Content-Type' => 'application/json');
            my $ua  = LWP::UserAgent->new;
            my $res = $ua->request($req);
            ok !$res->is_success;
            is $res->code, 400;
            is_deeply(JSON::decode_json($res->content), {error => 'no'});

            $req->uri($url . 'error');
            $res = $ua->request($req);
            ok !$res->is_success;
            is $res->code, 500;
            is $res->header('Content-Type'), 'application/json';
            like $res->content, qr/reason/;

            $req->uri($url . 'error2');
            $res = $ua->request($req);
            ok !$res->is_success;
            is $res->code, 500;
            is_deeply(JSON::decode_json($res->content),
              {error => 'no http code'});
        },
        server => sub {
            my $port = shift;
            Dancer::Config->load;
            setting startup_info => 0;
            setting port         => $port;
            setting show_errors  => 1;
            get '/'              => sub { halt send_error('no', 400) };
            get '/error'         => sub {
                halt send_error({reason => 'because', error => 'foo'}), 500;
            };
            get '/error2' => sub { halt send_error('no http code') };
            Dancer->dance();
        },
    );
}

