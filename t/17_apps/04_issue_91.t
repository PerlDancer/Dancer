use strict; use warnings;
use Test::More tests => 3, import => ['!pass'];

use Dancer::Test;

use lib ('t/lib');
use MyApp;

response_content_is [GET => "/"], "mainapp";
response_content_is [GET => "/foo"], "before block in foo";
response_content_is [GET => "/foo"], "before block in foo";
