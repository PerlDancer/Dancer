use strict;
use warnings;
use Test::More import => ['!pass'];
use Dancer::ModuleLoader;
use Dancer;
use Dancer::Cookie;

plan skip_all => "LWP is needed for this test"
  unless Dancer::ModuleLoader->load('LWP::UserAgent');
plan skip_all => "Test::TCP is needed for this test"
  unless Dancer::ModuleLoader->load("Test::TCP");

plan tests => 4;

my $check_expires = Dancer::Cookie::_epoch_to_gmtstring(time + 42);

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua   = LWP::UserAgent->new;
        my $req =
          HTTP::Request->new(GET => "http://127.0.0.1:$port/set_session/test");
        my $res = $ua->request($req);
        ok $res->is_success, 'req is success';
        my $cookie = $res->header('Set-Cookie');
        ok $cookie, 'cookie is set';
        my ($expires) = ($cookie =~ /expires=(.*?);/);
        ok $expires, 'expires is present in cookie';
        my $check_expires1 = Dancer::Cookie::_epoch_to_gmtstring(time + 42);
        my $check_expires2 =
          Dancer::Cookie::_epoch_to_gmtstring(time + 42 - 1);
        ok $expires eq $check_expires1 || $expires eq $check_expires2,
          'expire date is correct';
    },
    server => sub {
        my $port = shift;

        use t::lib::TestApp;
        Dancer::Config->load;

        setting session         => 'YAML';
        setting session_expires => 42;
        setting environment     => 'production';
        setting port            => $port;
        setting access_log      => 0;
        Dancer->dance();
    },
);
