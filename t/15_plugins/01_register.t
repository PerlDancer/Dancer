use strict;
use warnings;
use Test::More 'import' => ['!pass'], tests => 2;

use File::Spec;
use Dancer::Test;
use lib File::Spec->catdir( 't', 'lib' );
use TestApp;

$ENV{HTTP_REFERER} = 'http://www.google.com';
response_status_is [GET => '/'] => 200, "referer is not blocked";

$ENV{HTTP_REFERER} = 'http://www.foo.com';
response_status_is [GET => '/'] => 403, "referer is blocked";


