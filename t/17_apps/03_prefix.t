use Test::More tests => 5, import => ['!pass'];
use strict;
use warnings;

use Dancer;
use Dancer::Test;

prefix '/foo';

get '/' => sub {
    '/foo and /foo/'
};

get '/bar' => sub {
    "/foo/bar"
};

prefix undef;

get '/baz' => sub {
    "/baz"
};

response_content_is [ GET => "/foo/bar" ], "/foo/bar";
response_content_is [ GET => "/foo/" ],    "/foo and /foo/";
response_content_is [ GET => "/foo" ],     "/foo and /foo/";
response_doesnt_exist [ GET => '/foo/baz' ];
response_content_is [ GET => "/baz" ], "/baz";
