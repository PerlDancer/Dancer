use strict; use warnings;
use Test::More tests => 2, import => ['!pass'];

use Dancer::Test;

use lib ('t/lib');
use TestApp;

use Dancer ':syntax';

response_status_is [GET => "/send_error"], 599;
response_status_is [GET => "/die"], 599;
