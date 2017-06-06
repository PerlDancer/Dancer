# See Issue 1140
use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer;
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

plan skip_all => "skip test with Test::TCP in win32/cygwin" if ($^O eq 'MSWin32'or $^O eq 'cygwin');
plan skip_all => "Test::TCP is needed for this test"
    unless Dancer::ModuleLoader->load("Test::TCP" => "1.30");

use HTTP::Tiny;

use constant RAW_DATA => "foo=bar&bar=baz";

plan tests => 2;
my $host = '127.0.0.10';
Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $rawdata = RAW_DATA;
        my $ua = HTTP::Tiny->new;
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
);
