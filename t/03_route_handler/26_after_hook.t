use strict;
use warnings;

use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

ok(
    after sub {
        my $response = shift;
        $response->{content} = 'not index!';
    },
    'after hook is defined'
);

ok(
    get(
        '/' => sub {
            return 'index';
        }
    ),
    'index route is defined'
);

route_exists [ GET => '/' ];
response_content_is( [ GET => '/' ], 'not index!' );

done_testing;

