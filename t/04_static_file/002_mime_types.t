use strict;
use warnings;

use Dancer ':syntax';
use Dancer::ModuleLoader;

use Dancer::Test;
use Test::More import => ['!pass'];

plan tests => 12;

# set environment...
set public => path(dirname(__FILE__), 'static');
my $public = setting('public');

# test we do not have any mime_type alias defined.
is_deeply(mime->custom_types, {}, "No aliases present.");


my $path = '/hello.foo';

# check if fake request is working
response_exists [GET => $path], "static file is found for $path";
response_status_isnt [GET => $path] => 404;

# check that for unknown file types, the default value is set
response_headers_are_deeply [GET => $path] => ['Content-Type' => mime->default ],
  "$path is sent with default mime_type";

# we can change the default mime type
set default_mime_type => 'text/plain';

# get another response for same file
response_exists [GET => $path], "static file is found for $path";

# check that for unknown file types, the new default value is set
response_headers_are_deeply [GET => $path] => ['Content-Type' => 'text/plain'],
  "$path is sent with new default mime_type";

# check we can add a mime type
mime->add_type(foo => 'text/foo');
is mime->for_name("foo"), "text/foo", "can add an alias";

# check that mime type is returned in the aliases method
is_deeply(mime->custom_types, {foo => 'text/foo'}, "just the 'foo' alias.");

# prepare another fake request...
response_exists [GET => $path], "static file is found for $path";

# and that is now is returned being our new mime_type
response_headers_are_deeply [GET => $path] => ['Content-Type' => 'text/foo'],
  "$path is sent as text/foo";

# other test for standard extension
$path = '/hello.txt';

# we have a response
response_exists [GET => $path] => "static file is found for $path";

# and the response is text/plain
response_headers_are_deeply [GET => $path] => ['Content-Type' => 'text/plain'],
  "$path is sent as text/plain";

