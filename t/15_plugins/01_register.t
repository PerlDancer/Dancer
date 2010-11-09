use strict;
use warnings;
use Test::More 'import' => ['!pass'], tests => 2;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;
use TestApp;

$ENV{HTTP_REFERER} = 'http://www.google.com';
my $response = get_response_for_request(GET => '/');
is $response->{status}, 200, "referer is not blocked";

$ENV{HTTP_REFERER} = 'http://www.foo.com';
$response = get_response_for_request(GET => '/');
is $response->{status}, 403, "referer is blocked";

