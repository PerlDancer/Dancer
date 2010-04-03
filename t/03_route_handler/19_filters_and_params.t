use strict;
use warnings;
use Test::More tests => 3, import => ['!pass'];

# This test makes sure a before filter can access the request params

{
    use Dancer;

    before sub { 
        ok(defined(params->{'action'}), 
            "param action is defined in before filter");
        ok(defined(params->{'format'}), 
            "param format is defined in before filter");
    };

    get '/:action.:format' => sub {
        1;
    };
}

use lib 't';
use TestUtils;

my $response = get_response_for_request(GET => '/foo.json');
ok(defined($response), "response found for /foo.json");
