use strict;
use warnings;

use Test::More tests => 7, import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;
use Time::HiRes qw/gettimeofday tv_interval/;

my ($t0, $elapsed);

ok(
    hook before_template => sub {
        my $tokens = shift;
        $tokens->{foo} = 'bar';
        $t0 = [gettimeofday];
    }
);

ok(
    hook after_template_render => sub {
        my $full_content = shift;
        like $$full_content, qr/foo => bar/;
        my ( undef, $end ) = gettimeofday();
        $elapsed = tv_interval($t0);
    }
);

setting views => path( 't', '22_hooks', 'views' );

get '/' => sub {
    template 'index', { foo => 'baz' };
};

route_exists [ GET => '/' ];
response_content_like( [ GET => '/' ], qr/foo => bar/ );

ok $elapsed;
cmp_ok $elapsed, '>', 0;
