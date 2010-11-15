use Test::More import => ['!pass'];
use strict;
use warnings;

plan skip_all => 'Test::TCP is needed to run this test'
    unless Dancer::ModuleLoader->load('Test::TCP');

use LWP::UserAgent;

my $plack_available = Dancer::ModuleLoader->load('Plack::Request');
Dancer::ModuleLoader->load('Plack::Loader') if $plack_available;

plan tests => $plack_available ? 12 : 6;

my @handlers = ('Standalone');
push @handlers, 'PSGI' if $plack_available;

for my $handler (@handlers) {
Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;

        my $request = HTTP::Request->new(GET => "http://127.0.0.1:$port/req");
        $request->header('X-User-Head1' => 42);
        $request->header('X-User-Head2' => 43);

        my $res = $ua->request($request);
        ok($res->is_success, "$handler server responded");
        is($res->header('X-Foo'), 2);
        is($res->header('X-Bar'), 3);
        is($res->header('Content-Type'), 'text/plain');
    },
    server => sub {
        my $port = shift;
        use Dancer;
        
        setting apphandler => $handler;
        setting port => $port;
        setting show_errors => 1;
        setting access_log => 0;

        after sub {
            my $response = shift;
            $response->header('X-Foo', 2);
        };
        
        get '/req' => sub {
            is(request->header('X-User-Head1'), 42,
                "header X-User-Head1 is ok");
            is(request->header('X-User-Head2'), 43,
                "header X-User-Head2 is ok");
            Dancer::Response::headers('X-Bar', 3);
            content_type('text/plain');
        };
        
        if ($handler eq 'PSGI') {
            my $app = Dancer::Handler->get_handler()->dance;
            Plack::Loader->auto(port => $port)->run($app);
        }
        else {
            Dancer->dance();
        }
    },
);
}
