use strict;
use warnings;
use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

use lib 't/lib';

use LinkBlocker;

ok(
    get(
        '/test' => sub {
            return 'index';
        }
    ),
    'index route is defined'
);

route_exists [ GET => '/test' ];
response_content_is( [ GET => '/test' ], 'no content' );
response_status_is( [ GET => '/test' ], 202 );

done_testing;

