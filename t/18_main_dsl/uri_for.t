use strict;
use warnings;

use Dancer;
use Dancer::Test;
use Test::More import => ['!pass'];
plan tests => 1;

# taken from the doc
get '/' => sub {
   return uri_for('/path');
   # can be something like: http://localhost:3000/path
};

response_content_is [GET => '/'], 'http://localhost/path';
