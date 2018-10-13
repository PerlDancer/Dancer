use strict;
use warnings;

use Test::More tests => 6, import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;


my @events;

ok(
    hook before_template => sub {
        my $tokens = shift;
        $tokens->{foo} = 'bar';
        push @events, 'before_template_hook';
    }
);

ok(
    hook after_template_render => sub {
        my $full_content = shift;
        like $$full_content, qr/foo => bar/;
        push @events, 'after_template_hook';
    }
);

setting views => path( 't', '22_hooks', 'views' );

get '/' => sub {
    push @events, 'route_handler';
    template 'index', { foo => 'baz' };
};

route_exists [ GET => '/' ];
response_content_like( [ GET => '/' ], qr/foo => bar/ );


is_deeply(
    \@events,
    [ qw( route_handler before_template_hook after_template_hook ) ],
    "Hooks triggered as we expected",
);

