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

use HTTP::Tiny::NoProxy;

use constant RAW_DATA => "var: 2; foo: 42; bar: 57\nHey I'm here.\r\n\r\n";

my $host = '127.0.0.1';

plan tests => 6;
Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $rawdata = RAW_DATA;
        my $ua = HTTP::Tiny::NoProxy->new;
        my $headers = { 'Content-Length' => length($rawdata) };
        my $res = $ua->put("http://$host:$port/jsondata", { headers => $headers, content => $rawdata });

        ok $res->{success}, 'req is success';
        is $res->{content}, $rawdata, "raw_data is OK";

        # Now, turn off storing raw request body in RAM, check that it was
        # effective
        $res = $ua->put("http://$host:$port/setting/raw_request_body_in_ram/0");
        is $res->{status}, 200, 'success changing setting';
        diag($res->{content});

        $res = $ua->get("http://$host:$port/setting/raw_request_body_in_ram");
        is $res->{content}, "0", "setting change was stored";

        $res = $ua->put("http://$host:$port/jsondata", { headers => $headers, content => $rawdata });

        ok $res->{success}, 'req is success';
        is $res->{content}, "", "request body was empty with raw_request_body_in_ram false";

        

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
);
