package MyTest;

use strict;
use warnings;

use Test::More import => [ '!pass' ];

plan tests => 3;

use Dancer;
use Dancer::Test;

get '/user/*/**' => sub {
    var user => (splat)[0];
    pass;
};

get '/user/:id/useful_method' => sub {
    var 'user';
};

response_status_is '/user/yanick/wacka' => 404, "route doesn't exist";

response_status_is '/user/yanick/useful_method' => 200, 'route exists';
response_content_is '/user/yanick/useful_method' => 'yanick';
