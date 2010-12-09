# this test makes sure the auto_page feature works as expected
# whenever a template matches a requested path, a default route handler 
# takes care of rendering it.
use strict;
use warnings;
use Test::More import => ['!pass'], tests => 13;
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

use TestUtils;

{
    package Foo;
    use Dancer;

    set views => path(dirname(__FILE__), 'views');
    set auto_page => true;

    get '/' => sub { "<root>\n" };
    get '/simple' => sub { "simple\n" };
    get '/path/to' => sub { "nested\n" };
}

my $resp = get_response_for_request('GET' => '/hello');
ok( defined($resp), "response found for /hello");
is $resp->{content}, "Hello\n", "content looks good";

$resp = get_response_for_request('GET' => '/falsepage');
ok( defined($resp), "response found for non existent page");

is $resp->{status}, 404, "response is 404";

for my $test (
   [ '/' => "<root>\n" ],
   [ '/simple' => "simple\n" ],
   [ '/path/to' => "nested\n" ],
) {
   my ($path, $expected) = @$test;
   my $resp = get_response_for_request(GET => $path);
   ok( defined($resp), "response found for explicit route $path");
   is $resp->{status}, 200, "response is 200";
   is $resp->{content}, $expected, "content looks good";
}

