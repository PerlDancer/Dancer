# this test makes sure the auto_page feature works as expected
# whenever a template matches a requested path, a default route handler 
# takes care of rendering it.
use strict;
use warnings;
use Test::More import => ['!pass'], tests => 10;

use lib 't';
use TestUtils;

{
    package Foo;
    use Dancer;

    set auto_page => true;

    get '/' => sub { 1 };
}

my $req = fake_request(GET => '/hello');
Dancer::SharedData->request($req);

my $resp = Dancer::Renderer::get_action_response();

ok( defined($resp), "response found for /hello");
is $resp->{content}, 'H', "content looks good";

