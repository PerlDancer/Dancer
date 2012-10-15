use strict;
use warnings;

use Dancer ':syntax';
use Dancer::ModuleLoader;

use Dancer::Test;
use Test::More import => ['!pass'];

use HTTP::Date qw( time2str );

plan tests => 10;

# 1. test mime directly
{
    is(mime->for_file('foo.zip'), 'application/zip',
       "a mime_type is found with MIME::Types");

    is(mime->for_file('foo.nonexistent'), mime->default,
       'mime_type defaults to the default defined mime_type' );
}

# 2. test mimes of public files
{
    # set environment...
    set public => path(dirname(__FILE__), 'static');
    my $public = setting('public');

    # test we do not have any mime_type alias defined.
    is_deeply(mime->custom_types, {}, "No aliases present.");

    my $path = '/hello.foo';
    my $date = time2str( (stat "$public/$path")[9] );

    # check if fake request is working
    response_status_is [GET => $path] => 200, "static file is found for $path";

    # check that for unknown file types, the default value is set
    response_headers_are_deeply [GET => $path] => ['Content-Type' => mime->default, 'Last-Modified' => $date ],
      "$path is sent with default mime_type";

    # we can change the default mime type
    set default_mime_type => 'text/plain';

    # check that for unknown file types, the new default value is set
    response_headers_are_deeply [GET => $path] => ['Content-Type' => 'text/plain', 'Last-Modified' => $date],
      "$path is sent with new default mime_type";

    # check we can add a mime type
    mime->add_type(foo => 'text/foo');
    is mime->for_name("foo"), "text/foo", "can add an alias";

    # check that mime type is returned in the aliases method
    is_deeply(mime->custom_types, {foo => 'text/foo'}, "just the 'foo' alias.");

    # and that is now is returned being our new mime_type
    response_headers_are_deeply [GET => $path] => ['Content-Type' => 'text/foo', 'Last-Modified' => $date],
      "$path is sent as text/foo";

    # other test for standard extension
    $path = '/hello.txt';
    $date = time2str( (stat "$public/$path")[9] );

    # and the response is text/plain
    response_headers_are_deeply [GET => $path] => ['Content-Type' => 'text/plain', 'Last-Modified' => $date],
      "$path is sent as text/plain";
}

