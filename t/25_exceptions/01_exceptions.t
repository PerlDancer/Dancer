use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';
use Dancer::Test;

BEGIN { use_ok('Dancer::Exception', ':all'); }

set views => path( 't', '25_exceptions', 'views' );
set error_template => "error.tt";

# die in route
get '/die_in_route' => sub {
    die "die in route";
};

route_exists [ GET => '/die_in_route' ];
response_content_like( [ GET => '/die_in_route' ], qr|MESSAGE: <h2>runtime error</h2>| );
response_status_is( [ GET => '/die_in_route' ], 500 => "We get a 500 status" );

# raise in route
get '/raise_in_route' => sub {
    raise E_GENERIC;
};
route_exists [ GET => '/raise_in_route' ];
response_content_like( [ GET => '/raise_in_route' ], qr|MESSAGE: <h2>runtime error</h2>| );
response_status_is( [ GET => '/raise_in_route' ], 500 => "We get a 500 status" );

# die in hook
my $flag = 0;
hook after_template_render => sub {
    $flag++
      or die "die in hook";
};
get '/die_in_hook' => sub {
    template 'index', { foo => 'baz' };
};
route_exists [ GET => '/die_in_hook' ];
$flag = 0;
response_content_like( [ GET => '/die_in_hook' ], qr|MESSAGE: <h2>runtime error</h2>| );
$flag = 0;
response_status_is( [ GET => '/die_in_hook' ], 500 => "We get a 500 status" );

# raise in hook
my $flag;
hook before_template_render => sub {
    $flag++
      or raise E_GENERIC;
};
get '/raise_in_hook' => sub {
    template 'index', { foo => 'baz' };
};
route_exists [ GET => '/raise_in_hook' ];
$flag = 0;
response_content_like( [ GET => '/raise_in_hook' ], qr|MESSAGE: <h2>runtime error</h2>| );
$flag = 0;
response_status_is( [ GET => '/raise_in_hook' ], 500 => "We get a 500 status" );

done_testing();
