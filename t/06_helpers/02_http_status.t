use Test::More import => ['!pass'];

use Dancer::HTTP 'status';

my @tests = (
    {status => 'ok', expected => qr/200 OK/ },
    {status => '200', expected => qr/200 OK/ },
    {status => 'error', expected => qr/500 Internal Server Error/ },
    {status => '500', expected => qr/500 Internal Server Error/ },
    {status => 'not_found', expected => qr/404 Not found/ },
    {status => '404', expected => qr/404 Not found/ },
    {status => 'forbidden', expected => qr/503 Forbidden/ },
    {status => '503', expected => qr/503 Forbidden/ },
);

plan tests => scalar(@tests);

foreach my $test (@tests) {
    like(status($test->{status}), 
        $test->{expected}, 
        "status header looks good for ".$test->{status});
}

