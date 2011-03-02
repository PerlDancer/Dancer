# this test makes sure the auto_page feature works as expected
# whenever a template matches a requested path, a default route handler 
# takes care of rendering it.
use strict;
use warnings;
use Test::More import => ['!pass'], tests => 3;
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

use TestUtils;

{
    package Foo;
    use Dancer;

    set views => path(dirname(__FILE__), 'views');
    set auto_page => true;

    get '/' => sub { 1 };
}

my $resp = get_response_for_request('GET' => '/hello');
ok( defined($resp), "response found for /hello");
is $resp->{content}, "Hello\n", "content looks good";
Dancer::SharedData->reset_response();
eval { get_response_for_request('GET' => '/falsepage'); };
ok $@, 'Failed to get response for nonexistent page';
