use Test::More import => ['!pass'];
use strict;
use warnings;

plan skip_all => "LWP::UserAgent is needed to run this tests"
    unless Dancer::ModuleLoader->load('LWP::UserAgent');
plan skip_all => 'Test::TCP is needed to run this test'
    unless Dancer::ModuleLoader->load('Test::TCP');

plan tests => 3;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;

        my $request = HTTP::Request->new(GET => "http://127.0.0.1:$port/req");
        $request->header('X-User-Head1' => 42);
        $request->header('X-User-Head2' => 43);

        my $res = $ua->request($request);
        ok($res->is_success, "req is a success");
    },
    server => sub {
        my $port = shift;
            
        use Dancer;
        use Dancer::Config 'setting';
        
        setting port => $port;
        setting show_errors => 1;
        setting access_log => 0;

        get '/req' => sub {
            is(request->header('X-User-Head1'), 42,
                "header X-User-Head1 is ok");
            is(request->header('X-User-Head2'), 43,
                "header X-User-Head2 is ok");
        };
        
        Dancer->dance();
    },
);

