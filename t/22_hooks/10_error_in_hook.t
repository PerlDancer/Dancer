use strict;
use warnings;

use Test::More tests => 3, import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

hook before_template => sub {
    die "plop";
};

set views => path( 't', '22_hooks', 'views' );

get '/' => sub {
    template 'index', { foo => 'baz' };
};

route_exists [ GET => '/' ];
response_content_like( [ GET => '/' ], qr/Unable to process your query/ );
response_status_is( [ GET => '/' ], 500 => "We get a 500 status" );
