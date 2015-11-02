use strict;
use warnings;
use Test::More import => ['!pass'];
use LWP::UserAgent;

BEGIN {
    use Dancer::ModuleLoader;
    plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';
    plan skip_all => 'Test::TCP is needed to run this test'
      unless Dancer::ModuleLoader->load('Test::TCP' => "1.30");
}

plan tests => 4;

use Dancer ':syntax';
use Dancer::Test;

test();

sub test {
    Test::TCP::test_tcp(
        client => sub {
            my $port = shift;
            my $url  = "http://127.0.0.1:$port/";

            my $ua = LWP::UserAgent->new;
            for (qw/204 304/) {
                my $req = HTTP::Request->new( GET => $url . $_ );
                my $res = $ua->request($req);
                ok !$res->content, 'no content for '.$_;
                ok !$res->header('Content-Length'), 'no content-length for '.$_;
            }
        },
        server => sub {
            my $port = shift;
            set port => $port, server => '127.0.0.1', startup_info => 0;

            get '/204' => sub {
                status 204;
                  return 'foo'
            };
            get '/304' => sub {
                status 304;
                  return 'foo'
            };

            Dancer->dance();
        },
    );
}


