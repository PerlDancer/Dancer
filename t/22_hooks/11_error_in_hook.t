use strict;
use warnings;

use Test::More tests => 3, import => ['!pass'];
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
   hook ( after => sub { $var = 42; } ),
   'after hook is defined'
  );

get '/error' => sub {
    send_error "FAIL";
    # should not be executed
    $var = 75;
};

route_exists [ GET => '/error' ];
response_status_is( [ GET => '/' ], 500 => "We get a 500 status" );

is ($var, 42);
