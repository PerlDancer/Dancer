# See Issue 1140
use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer;
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use IO::Socket::INET;

plan skip_all => "skip test with Test::TCP in win32/cygwin" if ($^O eq 'MSWin32'or $^O eq 'cygwin');
plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Test::TCP" => "1.30");

use HTTP::Tiny::NoProxy;

use constant RAW_DATA => "foo=bar&bar=baz";

plan tests => 2;
my ($host, $port) = get_host_port();
diag "Selected $host:$port";
Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $rawdata = RAW_DATA;
        my $ua = HTTP::Tiny::NoProxy->new;
        my $headers = { 'Content-Length' => length($rawdata), 'Content-Type' => 'application/x-www-form-urlencoded' };
        my $res = $ua->request(POST => "http://$host:$port/jsondata", { headers => $headers, content => $rawdata });

        ok $res->{success}, 'req is success';
        is $res->{content}, $rawdata, "raw_data is OK";
    },
    server => sub {
        my $port = shift;

        use TestApp;
        Dancer::Config->load;

        set( environment  => 'production',
             port         => $port,
             server       => $host,
             startup_info => 0);
        Dancer->dance();
    },
    host => $host,
    port => $port,
);

# Work out the host and available port to use for the tests.
# Prefer 127.0.0.11, as race conditions on busy hosts are less likely
# than on 127.0.0.1 (see #1150), but if that won't work (e.g. FreeBSD
# boxes, which only have 127.0.0.1/32, not 127/8) then fall back to
# 127.0.0.1.
sub get_host_port {
    for my $host (qw(127.0.0.11 127.0.0.1)) {
        my $sock = IO::Socket::INET->new(
            Listen => 1,
            LocalAddr => $host,
            LocalPort => 0,
        );
        if ($sock) {
            my $port = $sock->sockport;
            $sock->close;
            return ($host, $port);
        }
    }
}


