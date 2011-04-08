# this test makes sure the auto_page feature works as expected
# whenever a template matches a requested path, a default route handler 
# takes care of rendering it.
use strict;
use warnings;
use Test::More import => ['!pass'], tests => 3;

use Dancer::Test;

{
    package Foo;
    use Dancer;

    set views => path(dirname(__FILE__), 'views');
    set auto_page => true;

    get '/' => sub { 1 };
}

response_exists [GET => '/hello'], "response found for /hello";

response_content_is [GET => '/hello'], "Hello\n", "content looks good";

eval { get_response_for_request('GET' => '/falsepage'); };
ok $@, 'Failed to get response for nonexistent page';
