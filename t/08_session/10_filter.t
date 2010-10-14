use strict;
use warnings;

use Test::More import => ['!pass'], tests => 5;
use Dancer ':syntax';
use Dancer::Test;

ok(
    before(
        sub {
            my $data = session;
            #warn "on a $data";
            #redirect '/nonexistent'
              #unless session || request->path =~ m{/login}sxm;
        }
    ),
    'before filter is defined'
);

ok(
    get(
        '/login' => sub {
            '/login';
        }
    ),
    'login route is defined'
);

route_exists       [ GET => '/login' ];
response_exists    [ GET => '/login' ];
response_status_is [ GET => '/login' ], 200,
  'response status is 200 for /login';