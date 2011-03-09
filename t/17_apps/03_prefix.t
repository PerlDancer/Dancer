use Test::More tests => 9, import => ['!pass'];
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

prefix '/foobar';

get '/' => sub {
    "/foobar/",;
};

response_content_is [ GET => "/foo/bar" ], "/foo/bar";
response_content_is [ GET => "/foo/" ],    "/foo and /foo/";
response_content_is [ GET => "/foo" ],     "/foo and /foo/";
response_doesnt_exist [ GET => '/foo/baz' ];
response_content_is   [ GET => "/baz" ], "/baz";
response_content_is   [ GET => "/foobar" ], "/foobar/";
response_content_is   [ GET => "/foobar/" ], "/foobar/";
response_doesnt_exist [ GET => '/foobar/foobar/' ];
response_doesnt_exist [ GET => '/foobar/foobar/foobar/' ];
