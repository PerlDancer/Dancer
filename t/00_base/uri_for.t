use Test::More import => ['!pass'];
use strict;
use warnings;

plan tests => 1;

use Dancer;
use Dancer::Test;

get '/foo' => sub {
    return uri_for('/foo');
};

response_content_is [GET => '/foo'], 
    'http://localhost/foo', 
    "uri_for works as expected";

