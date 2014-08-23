use strict;
use warnings;

use Test::More tests => 6;

use Dancer::Test;

{
    package MyApp;

    use Dancer ':tests';

    get '/' => sub { return join ':', map { "!$_!" } param_array( 'foo' ) };

    get '/scalar_context' => sub {
        scalar param_array('foo');
    }
}


response_content_is '/' => '', "no params whatsoever";
response_content_is '/?foo=one' => '!one!', "one parameter";
response_content_is '/?foo=one;foo=two' => '!one!:!two!', "two parameters";

response_content_is '/scalar_context' => 0, 'no params';
response_content_is '/scalar_context?foo=one' => 1, 'one param';
response_content_is '/scalar_context?foo=one;foo=two' => 2, 'two params';


