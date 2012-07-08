use strict;
use warnings;
use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

use lib 't/lib';

plan tests => 6;

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

# home-made hooks (test taken from Dancer 2)

my $counter = 0;

{
    use Dancer;
    use t::lib::Hookee;

    hook 'start_hookee' => sub {
        'hook for plugin';
    };

    get '/hooks_plugin' => sub {
        $counter++;
        some_keyword();
    };

}

is $counter, 0, "the hook has not been executed";
my $r = dancer_response(GET => '/hooks_plugin');
is $counter, 1, "the hook has been executed exactly once";

