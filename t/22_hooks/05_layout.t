use strict;
use warnings;

use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

plan tests => 6;

my $time = localtime();

ok(
    hook before_layout_render => sub {
        my $tokens = shift;
        $tokens->{time} = $time;
    }
);

ok(
    hook after_layout_render => sub {
        my $full_content = shift;
        like $$full_content, qr/start/;
        like $$full_content, qr/stop/;
    }
);

set views => path( 't', '22_hooks', 'views' );
set layout => 'main';

get '/' => sub {
    template 'index', { foo => 'baz' };
};

route_exists [ GET => '/' ];
response_content_like( [ GET => '/' ], qr/start $time/ );
