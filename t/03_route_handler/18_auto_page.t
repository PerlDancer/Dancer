# this test makes sure the auto_page feature works as expected
# whenever a template matches a requested path, a default route handler 
# takes care of rendering it.
use strict;
use warnings;
use Test::More import => ['!pass'], tests => 4;

use t::lib::TestUtils;

{
    package Foo;
    use Dancer;

    set views => path(dirname(__FILE__), 'views');
    set auto_page => true;

    get '/' => sub { 1 };
}

Dancer::Route->init;

my $resp = get_response_for_request('GET' => '/hello');
ok( defined($resp), "response found for /hello");
is $resp->{content}, "Hello\n", "content looks good";

$resp = get_response_for_request('GET' => '/falsepage');
ok( defined($resp), "response found for non existent page");

is $resp->{status}, 404, "response is 404";
