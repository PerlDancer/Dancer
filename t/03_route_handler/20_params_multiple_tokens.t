use strict;
use warnings;
use Test::More tests => 2, import => ['!pass'];

{
    use Dancer;

    get '/:resource/:id.:format' => sub {
        [ params->{'resource'}, 
          params->{'id'}, 
          params->{'format'} ];
    };
}

use lib 't';
use TestUtils;

my $response = get_response_for_request(GET => '/user/42.json');
ok( defined($response), "repsonse found for '/user/42.json'" );

is_deeply( $response->{content}, ['user', '42', 'json'],
    "params are parsed as expected" );

