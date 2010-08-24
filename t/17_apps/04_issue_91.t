use strict; use warnings;
use Test::More tests => 4, import => ['!pass'];

use Dancer::Test;

use lib ('t/lib');
use MyApp;

use Dancer ':syntax';

response_content_is [GET => "/"], "mainapp";
response_content_is [GET => "/foo/"], "before block in foo";
response_content_is [GET => "/foo/"], "before block in foo";
response_content_is [GET => "/"], "mainapp";
