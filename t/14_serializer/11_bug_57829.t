use strict; use warnings;
use Test::More import => ['!pass'];

# Requires
plan skip_all => 'Test::TCP is needed to run this test'
    unless Dancer::ModuleLoader->load('Test::TCP');
plan skip_all => "JSON needed for this test"
    unless Dancer::ModuleLoader->load('JSON');

plan tests => 3;

use LWP::UserAgent;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new();

        my $request = HTTP::Request->new(GET => "http://127.0.0.1:$port/");
        ok my $res = $ua->request($request);
        $res->header('Acccept' => 'application/json');
        ok $res->header('X-Test');
        is $res->header('X-Test'), 'ok';
    },
    server => sub {
        my $port  = shift;
        use Dancer;
        set serializer   => 'JSON',
            startup_info => 0,
            port         => $port;
        get '/' => sub {
            header 'X-Test' => 'ok';
            {body => 'ok'}
        };
        dance();
    },
);

