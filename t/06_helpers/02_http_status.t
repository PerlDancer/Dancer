use Test::More import => ['!pass'];

use Dancer::HTTP;

my @tests = (
    {status => 'ok', expected => 200 },
    {status => '200', expected => 200 },
    {status => 'created', expected => 201 },
    {status => '201', expected => 201 },
    {status => 'accepted', expected => 202 },
    {status => '202', expected => 202 },
    {status => 'no_content', expected => 204 },
    {status => '204', expected => 204 },
    {status => 'reset_content', expected => 205 },
    {status => '205', expected => 205 },
    {status => '302', expected => 302 },
    {status => 'bad_request', expected => 400 },
    {status => '400', expected => 400 },
    {status => 'forbidden', expected => 403 },
    {status => 'not_found', expected => 404 },
    {status => 'Not Found', expected => 404 },
    {status => '404', expected => 404 },
    {status => 'internal_server_error', expected => 500 },

    # additional aliases
    {status => 'error', expected => 500 },
);

plan tests => scalar(@tests);

foreach my $test (@tests) {
    is(Dancer::HTTP->status($test->{status}),
        $test->{expected},
        "status header looks good for ".$test->{status});
}

