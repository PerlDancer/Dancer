use strict;
use warnings;

use Test::More tests => 2;

use Dancer ':tests';
use Dancer::Test;

my @custom_header = ( 'X-Fruity' => 'tropical' );

get '/' => sub {
    headers @custom_header;

    halt( 'ABORT!' );
};

response_headers_include [ GET => '/' ] => \@custom_header, "headers kept";
response_content_is( '/', 'ABORT!' );
