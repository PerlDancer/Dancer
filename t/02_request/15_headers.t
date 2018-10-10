use Test::More import => ['!pass'];
use strict;
use warnings;

plan skip_all => "skip test with Test::TCP in win32" if $^O eq 'MSWin32';
plan skip_all => 'Test::TCP is needed to run this test'
    unless Dancer::ModuleLoader->load('Test::TCP' => "1.30");

use HTTP::Tiny::NoProxy;

my $plack_available = Dancer::ModuleLoader->load('Plack::Request');
Dancer::ModuleLoader->load('Plack::Loader') if $plack_available;

plan tests => $plack_available ? 12 : 6;

my @handlers = ('Standalone');
push @handlers, 'PSGI' if $plack_available;

for my $handler (@handlers) {
Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua = HTTP::Tiny::NoProxy->new;

        my $headers = { 'X-User-Head1' => 42, 'X-User-Head2' => 43 };

        my $res = $ua->get("http://127.0.0.1:$port/req", { headers => $headers });
        ok($res->{success}, "$handler server responded");
        is($res->{headers}{'x-foo'}, 2);
        is($res->{headers}{'x-bar'}, 3);
        is($res->{headers}{'content-type'}, 'text/plain');
    },
    server => sub {
        my $port = shift;
        use Dancer;

        set( apphandler   => $handler,
             port         => $port,
             server       => '127.0.0.1',
             show_errors  => 1,
             startup_info => 0 );

        hook after => sub {
            my $response = shift;
            $response->header('X-Foo', 2);
        };

        get '/req' => sub {
            is(request->header('X-User-Head1'), 42,
                "header X-User-Head1 is ok");
            is(request->header('X-User-Head2'), 43,
                "header X-User-Head2 is ok");
            headers('X-Bar', 3);
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
