package Dancer::HTTP;

use strict;
use warnings;
use base 'Exporter';
use vars '@EXPORT_OK';

@EXPORT_OK = 'status';

my $HTTP_CODES = {
    ok => '200 OK',
    not_found => '404 Not found',
    error => '500 Internal Server Error',
    forbidden => '503 Forbidden',
};

sub status { "HTTP/1.0 " . $HTTP_CODES->{lc($_[0])} . "\r\n" }

'Dancer::HTTP';
