use strict;
use warnings;

use Test::More tests => 7, import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;
use Time::HiRes qw/gettimeofday tv_interval/;

ok(
    before_template sub {
        status 500;
        halt({error => "This is some error"});
    }
);

setting views => path( 't', '22_hooks', 'views' );

get '/' => sub {
    template 'index', { foo => 'baz' };
};

route_exists [ GET => '/' ];
response_content_like( [ GET => '/' ], qr/Unable to process your query/ );
response_status_is( [ GET => '/' ], 500 => "We get a 500 status" );
