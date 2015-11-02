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

plan tests => 4;

set serializer => 'JSON';

my $data = { foo => 'bar' };

Test::TCP::test_tcp(
    client => sub {
        my $port    = shift;
        my $ua      = LWP::UserAgent->new;
        my $request = HTTP::Request->new( GET => "http://127.0.0.1:$port/" );
        my $res;

        $res = $ua->request($request);
        ok( $res->is_success, 'Successful response from server' );
        like(
            $res->content,
            qr/"foo" \s \: \s "bar"/x,
            'Correct content',
        );

        # new request, no serializer
        $res = $ua->request($request);
        ok( $res->is_success, 'Successful response from server' );
        like($res->content, qr/HASH\(0x.+\)/,
            'Serializer undef, response not serialised');
    },

    server => sub {
        my $port = shift;
        use Dancer ':tests';

        set( apphandler   => 'Standalone',
             port         => $port,
             server       => '127.0.0.1',
             show_errors  => 1,
             startup_info => 0 );

        get '/' => sub { $data };

        hook after => sub { set serializer => undef };

        Dancer->dance();
    },
);

