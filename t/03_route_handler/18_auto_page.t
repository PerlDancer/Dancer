# this test makes sure the auto_page feature works as expected
# whenever a template matches a requested path, a default route handler 
# takes care of rendering it.
use strict;
use warnings;
use Test::More import => ['!pass'], tests => 4;
use Dancer::Test;

{
    package Foo;
    use Dancer;

    before_template sub {
        my $tokens = shift;
        $tokens->{title} = "Dancer";
    };

    set auto_page => true, views => path(dirname(__FILE__), 'views');

    get '/' => sub { 1 };
}

response_status_is  [GET => '/hello'] => 200, "response found for /hello";
response_content_is [GET => '/hello'] => "Hello\n", "content looks good";

response_status_is  [GET => '/falsepage'] => 500;
response_content_like [GET => '/error'] => qr/ERROR: Dancer\n/, "error page looks OK";
