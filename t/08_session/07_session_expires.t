use strict;
use warnings;
use Test::More import => ['!pass'];

# Freeze time!  Now we can precalculate expiration times.
# This has to come before Dancer loads.
my $Time = 1302483506;
BEGIN {
    *CORE::GLOBAL::time = sub () { return $Time };
}

use Dancer::ModuleLoader;
use Dancer;
use Dancer::Cookie;

plan skip_all => "Test::TCP is needed for this test"
  unless Dancer::ModuleLoader->load("Test::TCP");
plan skip_all => "YAML is needed for this test"
  unless Dancer::ModuleLoader->load("YAML");

plan tests => 8;

use LWP::UserAgent;

my %tests = (
    42          => 'Mon, 11-Apr-2011 00:59:08 GMT',
    "+36h"      => 'Tue, 12-Apr-2011 12:58:26 GMT',
);

for my $session_expires (keys %tests) {
    my $cookie_expires = $tests{$session_expires};

    note "Translate from $session_expires";

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

            is $expires, $cookie_expires, 'expire date is correct';
        },
        server => sub {
            my $port = shift;

            use File::Spec;
            use lib File::Spec->catdir( 't', 'lib' );
            use TestApp;
            Dancer::Config->load;

            setting session         => 'YAML';
            setting session_expires => $session_expires;
            setting environment     => 'production';
            setting port            => $port;
            setting startup_info    => 0;
            Dancer->dance();
        },
    );
}
