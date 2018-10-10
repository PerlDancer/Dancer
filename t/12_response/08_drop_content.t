use strict;
use warnings;
use Test::More import => ['!pass'];
use HTTP::Tiny::NoProxy;

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

            my $ua = HTTP::Tiny::NoProxy->new;
            for (qw/204 304/) {
                my $res = $ua->get($url . $_);
                ok !$res->{content}, 'no content for '.$_;
                ok !$res->{headers}{'content-length'}, 'no content-length for '.$_;
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


