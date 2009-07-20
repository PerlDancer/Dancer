package Dancer::HTTP;

use strict;
use warnings;
use base 'Exporter';
use vars '@EXPORT_OK';

@EXPORT_OK = 'status';

my $HTTP_CODES = {
    200 => '200 OK',
    404 => '404 Not found',
    500 => '500 Internal Server Error',
    503 => '503 Forbidden',
};

# aliases
$HTTP_CODES->{ok} = $HTTP_CODES->{200};
$HTTP_CODES->{not_found} = $HTTP_CODES->{404};
$HTTP_CODES->{error} = $HTTP_CODES->{500};
$HTTP_CODES->{forbidden} = $HTTP_CODES->{503};

sub status { 
    my $name = shift;
    return undef unless exists $HTTP_CODES->{lc($name)};
    return "HTTP/1.0 " . $HTTP_CODES->{lc($name)} . "\r\n";
}

'Dancer::HTTP';
