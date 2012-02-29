use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';
use Dancer::Test;

BEGIN { use_ok('Dancer::Exception', ':all'); }

set views => path( 't', '25_exceptions', 'views' );

{
    # raise in hook but catch it from route
    my $flag = 0;
    my $properly_caught_error = 0;
    hook before_template_render => sub {
        $flag++
          or raise Generic => 'foo5';
    };
    get '/raise_in_hook' => sub {
        try {
            # should raise
            template 'index', { foo => 'baz5' };
        } catch {
            $properly_caught_error = 1;
            # won't raise, flag is > 0
            template 'index', { foo => 'baz5' };
        }
    };
    route_exists [ GET => '/raise_in_hook' ];
    $flag = 0;
    response_status_is( [ GET => '/raise_in_hook' ], 200 => "route didn't error");
    is $properly_caught_error, 1, 'properly caught exception';
    $flag = 0;
    response_content_like( [ GET => '/raise_in_hook' ], qr|foo => baz5| );
}

done_testing();
