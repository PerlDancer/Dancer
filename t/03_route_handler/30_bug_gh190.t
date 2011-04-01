use strict;
use warnings;

use Test::More tests => 6, import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

my $i = 0;

ok( before( sub { redirect '/somewhere' } ) );

ok( get( '/', sub { $i++; 'Hello' } ) );

route_exists                [ GET => '/' ];
response_headers_are_deeply [ GET => '/' ],
  [ 'Location' => '/somewhere' ];
response_content_is [ GET => '/' ], '';
is $i, 0;
