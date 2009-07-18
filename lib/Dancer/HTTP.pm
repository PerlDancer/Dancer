package Dancer::HTTP;

use strict;
use warnings;

my $HTTP_CODES = {
    ok => '200 OK',
    not_found => '404 Not found',
    error => '500 Internal Server Error',
    forbidden => '503 Forbidden',
};

sub status { "HTTP/1.0 " . $HTTP_CODES->{lc($_[1])} . "\r\n" }

'Dancer::HTTP';
