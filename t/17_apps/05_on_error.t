use strict; use warnings;
use Test::More tests => 1, import => ['!pass'];

use Dancer::Test;

use lib ('t/lib');
use TestApp;

use Dancer ':syntax';

response_status_is [GET => "/error"], 599;
