use strict;
use warnings;
use Test::More tests => 2, import => ['!pass'];

# This test makes sure a before filter can access the request params

{
    use Dancer ':syntax';

    before sub { 
        ok(defined(params->{'format'}), 
            "param format is defined in before filter");
    };

    get '/foo.:format' => sub {
        1;
    };
}

use t::lib::TestUtils;

my $response = get_response_for_request(GET => '/foo.json');
ok(defined($response), "response found for /foo.json");
