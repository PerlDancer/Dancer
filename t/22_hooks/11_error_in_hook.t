use strict;
use warnings;

use Test::More tests => 10, import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

hook before_template => sub {
    status 500;
    halt({error => "This is some error"});
};

set views => path( 't', '22_hooks', 'views' );

get '/' => sub {
    template 'index', { foo => 'baz' };
};

route_exists [ GET => '/' ];
response_content_like( [ GET => '/' ], qr/Unable to process your query/ );
response_status_is( [ GET => '/' ], 500 => "We get a 500 status" );



my $var = 5;

ok(
   hook ( after => sub { 
              $var = 42;
 } ),
   'after hook is defined'
  );

get '/error' => sub {
    send_error "FAIL";
    # should not be executed
    fail("This code should not be executed (1)");
};

route_exists [ GET => '/error' ];
response_status_is( [ GET => '/error' ], 500 => "We get a 500 status" );

is ($var, 42, "The after hook were called even after a send error");

get '/halt_me' => sub {
    halt({error => "This is some error"});
    # should not be executed
    fail("This code should not be executed (2)");
};

$var = 5;

route_exists [ GET => '/halt_me' ];
response_status_is( [ GET => '/halt_me' ], 500 => "We get a 200 status" );

is ($var, 5, "The after hook is bypassed if in a 'halt' state, as it was before version 1.3080");
