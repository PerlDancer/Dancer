use Test::More tests => 3, import => ['!pass'];
use strict;
use warnings;

use Dancer;
use Dancer::Test;

prefix '/foo';

get '/bar' => sub {
    "/foo/bar"
};

prefix undef;

get '/baz' => sub {
    "/baz"
};

response_content_is [GET => "/foo/bar"], "/foo/bar";
response_doesnt_exist [GET => '/foo/baz'];
response_content_is [GET => "/baz"], "/baz";
