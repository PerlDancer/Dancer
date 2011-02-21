use strict;
use warnings;

use Test::More tests => 10, import => ['!pass'];
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

ok(
    get '/layout_empty_params_passed' => sub {
        layout 'main';
        template 'index', {};
    }
);

route_exists [ GET => '/layout_empty_params_passed' ];
response_content_like( [ GET => '/layout_empty_params_passed' ], qr/layout:bar\ncontent:foo => bar/ );

ok(
    get '/layout_but_no_params_passed' => sub {
        layout 'main';
        template 'index';
    }
);

route_exists [ GET => '/layout_but_no_params_passed' ];
response_content_like( [ GET => '/layout_but_no_params_passed' ], qr/layout:bar\ncontent:foo => bar/ );
