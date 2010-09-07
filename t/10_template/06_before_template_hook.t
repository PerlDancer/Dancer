use strict;
use warnings;

use Test::More tests => 4, import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

ok(
    before_template sub {
        my $tokens = shift;
        $tokens->{foo} = 'bar';
    }
);

setting views => path('t', '10_template', 'views');

ok(
    get '/' => sub {
        template 'index', {foo => 'baz'};
    }
);

route_exists [ GET => '/' ];
response_content_like( [ GET => '/' ], qr/foo => bar/ );
