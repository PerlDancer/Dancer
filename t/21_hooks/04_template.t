use strict;
use warnings;

use Test::More tests => 7, import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;
use Time::HiRes qw/gettimeofday/;

my ($start, $diff);

ok(
    before_template sub {
        my $tokens = shift;
        $tokens->{foo} = 'bar';
        (undef, $start) = gettimeofday();
    }
);

ok(
    hook after_template_render => sub {
        my (undef, $end) = gettimeofday();
        $diff = $end - $start;
    }
);

setting views => path('t', '21_hooks', 'views');

ok(
    get '/' => sub {
        template 'index', {foo => 'baz'};
    }
);

route_exists [ GET => '/' ];
response_content_like( [ GET => '/' ], qr/foo => bar/ );

ok $diff;
cmp_ok $diff, '>', 0;
