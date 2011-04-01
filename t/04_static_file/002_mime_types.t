use strict;
use warnings;

use Dancer ':syntax';
use Dancer::ModuleLoader;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;
use Test::More import => ['!pass'];

plan tests => 11;

# set environment...
set public => path(dirname(__FILE__), 'static');
my $public = setting('public');

# test we do not have any mime_type alias defined.
is_deeply(mime->custom_types, {}, "No aliases present.");

# create fake request
my $path = '/hello.foo';
my $request = fake_request(GET => $path);
Dancer::SharedData->request($request);

# check if fake request is working
my $resp = Dancer::Renderer::get_file_response();
ok(defined($resp), "static file is found for $path");

# check that for unknown file types, the default value is set
my %headers = @{$resp->headers_to_array};
is($headers{'Content-Type'}, mime->default, "$path is sent with default mime_type");

# we can change the default mime type
set default_mime_type => 'text/plain';

# get another response for same file
$resp = Dancer::Renderer::get_file_response();
ok(defined($resp), "static file is found for $path");

# check that for unknown file types, the new default value is set
%headers = @{$resp->headers_to_array};
is($headers{'Content-Type'}, "text/plain", "$path is sent with new default mime_type");

# check we can add a mime type
mime->add_type(foo => 'text/foo');
is mime->for_name("foo"), "text/foo", "can add an alias";

# check that mime type is returned in the aliases method
is_deeply(mime->custom_types, {foo => 'text/foo'}, "just the 'foo' alias.");

# prepare another fake request...
Dancer::SharedData->request($request);
$resp = Dancer::Renderer::get_file_response();
ok( defined($resp), "static file is found for $path");

# and that is now is returned being our new mime_type
%headers = @{$resp->headers_to_array};
is_deeply(\%headers,
          {'Content-Type' => 'text/foo'},
          "$path is sent as text/foo");

# other test for standard extension
$path = '/hello.txt';
$request = fake_request(GET => $path);
Dancer::SharedData->request($request);
$resp = Dancer::Renderer::get_file_response();

# we have a response
ok( defined($resp), "static file is found for $path");

# and the response is text/plain
%headers = @{$resp->headers_to_array};
is_deeply(\%headers, 
    {'Content-Type' => 'text/plain'},
    "$path is sent as text/plain");
