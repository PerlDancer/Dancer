use Test::More tests => 12, import => ['!pass'];
use strict;
use warnings;

use Dancer;
use Dancer::Test;

is prefix, '', 'prefix returns empty string initially';

prefix '/foo';

is prefix, '/foo', 'prefix returns the currently set prefix';

get '/' => sub {
    '/foo and /foo/'
};

get '/bar' => sub {
    "/foo/bar"
};

prefix undef;

is prefix, '', 'prefix returns empty string after prefix is unset';

get '/baz' => sub {
    "/baz"
};

prefix '/foobar';

get '/' => sub {
    "/foobar/",;
};

response_content_is [ GET => "/foo/bar" ], "/foo/bar";
response_content_is [ GET => "/foo/" ],    "/foo and /foo/";
response_content_is [ GET => "/foo" ],     "/foo and /foo/";
response_status_is  [ GET => '/foo/baz' ], 404;
response_content_is [ GET => "/baz" ],     "/baz";
response_content_is [ GET => "/foobar" ],  "/foobar/";
response_content_is [ GET => "/foobar/" ], "/foobar/";
response_status_is  [ GET => '/foobar/foobar/' ], 404;
response_status_is  [ GET => '/foobar/foobar/foobar/' ], 404;
