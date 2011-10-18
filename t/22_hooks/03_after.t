use strict;
use warnings;

use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

plan tests => 3;

ok(
   hook(after =>
        sub {
            my $response = shift;
            $response->content('not index!');
        }
    ),
    'after hook is defined'
);

get(
    '/' => sub {
        return 'index';
    }
);

route_exists [ GET => '/' ];
response_content_is( [ GET => '/' ], 'not index!' );
