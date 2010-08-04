use strict;
use warnings;
use Test::More tests => 4, import => ['!pass'];
use Dancer::Test;


# This test makes sure a before filter can access the request params

{
    use Dancer ':syntax';
    # set 'log' => 'core';
    # set logger => 'console';

    before sub { 
        ok(defined(params->{'format'}), "param format is defined in before filter");
    };

    get '/foo.:format' => sub {
        ok(defined(params->{'format'}), "param format is defined in route handler");
        1;
    };
}

route_exists [GET => '/foo.json'];
response_content_is [GET => '/foo.json'], 1;
