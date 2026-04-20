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

plan tests => 3;

set serializer => 'JSON';

my $data = { foo => 'bar' };

Test::TCP::test_tcp(
    client => sub {
        my $port    = shift;
        my $ua      = LWP::UserAgent->new;
        my $request = HTTP::Request->new(
            PUT => "http://127.0.0.1:$port/deserialization",
            [
                Host         => 'localhost',
                Content_Type => 'application/json'
            ],
            to_json($data),
        );
        my $res = $ua->request($request);
        ok $res->is_success, 'Successful response from server';
        is_deeply from_json($res->content), $data, 'Correct content';
    },
    server => sub {
        my $port = shift;
        use Dancer ':tests';
        set(
            apphandler   => 'Standalone',
            port         => $port,
            show_errors  => 0,
            startup_info => 0,
        );
        put '/deserialization' => sub { $data };
        Dancer->dance;
    },
);

Test::TCP::test_tcp(
    client => sub {
        my $port    = shift;
        my $ua      = LWP::UserAgent->new;
        my $request = HTTP::Request->new(
            PUT => "http://127.0.0.1:$port/deserialization",
            [
                Host         => 'localhost',
                Content_Type => 'application/json'
            ],
            # broken JSON
            '{ "foo": "bar", }',
        );
        my $res = $ua->request($request);
        is $res->code, 400, '400 bad request';
    },
    server => sub {
        my $port = shift;
        use Dancer ':tests';
        set(
            apphandler   => 'Standalone',
            port         => $port,
            show_errors  => 1,
            startup_info => 0,
        );
        put '/deserialization' => sub { $data };
        Dancer->dance;
    },
);



