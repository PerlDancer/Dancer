use Dancer ':tests';
use Dancer::Test;
use Test::More;
use Dancer::ModuleLoader;
use LWP::UserAgent;

plan skip_all => "skip test with Test::TCP in win32" if  $^O eq 'MSWin32';
plan skip_all => 'Test::TCP is needed to run this test'
    unless Dancer::ModuleLoader->load('Test::TCP' => "1.30");

plan skip_all => 'JSON is needed to run this test'
    unless Dancer::ModuleLoader->load('JSON');

plan tests => 2;

my $unicode = "\x{30dc}\x{a9}";

Test::TCP::test_tcp(
    client => sub {
        my $port    = shift;
        my $ua      = LWP::UserAgent->new;
        my $request = HTTP::Request->new(
            POST => "http://127.0.0.1:$port/foo/$unicode",
            [
                Host         => 'localhost',
                Content_Type => 'application/json',
            ],
            to_json({ foo => 'bar' }),
        );
        my $res = $ua->request($request);
        ok $res->is_success, 'Successful response from server';
        is $res->content, 1, 'Correct content';
    },
    server => sub {
        my $port = shift;
        use Dancer ':tests';
        set(
            apphandler   => 'Standalone',
            port         => $port,
            show_errors  => 0,
            startup_info => 0,
            charset      => 'utf-8',
            serializer   => 'JSON',
        );
        post '/foo/*' => sub {
            params->{splat}[0] eq $unicode;
        };
        Dancer->dance;
    },
);
