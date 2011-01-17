use Test::More tests => 4, import => ['!pass'];
use strict;
use warnings;
use Dancer::Request;
use Dancer::SharedData;

# the request with a cookie string
my $env = {
    REQUEST_METHOD => 'GET',
    SCRIPT_NAME => '/',
    COOKIE => 'test_cookie=42',
};
my $request = Dancer::Request->new($env);
Dancer::SharedData->request($request);

# testing
use Dancer::Cookies;
ok(Dancer::Cookies->init, "Dancer::Cookies->init");

is_deeply(Dancer::Cookies->cookies, { 
    test_cookie => bless { 
        name => 'test_cookie', 
        value => [42],
        path => '/'}, 'Dancer::Cookie'}, 
    "cookies look good");

ok(! Dancer::Cookies->has_changed({name => 'test_cookie', value => 42}), 
    "cookie did not change");

ok(Dancer::Cookies->has_changed({name => 'test_cookie', value => 43}), 
    "cookie changed");

