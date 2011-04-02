use strict;
use warnings;
use Test::More tests => 2, import => ['!pass'];

{
    use Dancer ':syntax';

    get '/:resource/:id.:format' => sub {
        [ params->{'resource'}, 
          params->{'id'}, 
          params->{'format'} ];
    };
}

use Dancer::Test;

response_exists [GET => '/user/42.json'] => "response found for '/user/42.json'";

response_content_is_deeply [GET => '/user/42.json'] => ['user', '42', 'json'],
  "params are parsed as expected" ;

