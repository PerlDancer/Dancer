use Test::More import => ['!pass'];

use Dancer::HTTP;

my @tests = (
    {status => 'ok', expected => qr/200/ },
    {status => '200', expected => qr/200/ },
    {status => 'created', expected => qr/201/ },
    {status => '201', expected => qr/201/ },
    {status => 'accepted', expected => qr/202/ },
    {status => '202', expected => qr/202/ },
    {status => 'no_content', expected => qr/204/ },
    {status => '204', expected => qr/204/ },
    {status => 'reset_content', expected => qr/205/ },
    {status => '205', expected => qr/205/ },
    {status => '302', expected => qr/302/ },
    {status => 'bad_request', expected => qr/400/ },
    {status => '400', expected => qr/400/ },
    {status => 'forbidden', expected => qr/403/ },
    {status => 'not_found', expected => qr/404/ },
    {status => '404', expected => qr/404/ },
    {status => 'internal_server_error', expected => qr/500/ },

    # additional aliases
    {status => 'error', expected => qr/500/ },
);

plan tests => scalar(@tests);

foreach my $test (@tests) {
    like(Dancer::HTTP->status($test->{status}),
        $test->{expected},
        "status header looks good for ".$test->{status});
}

