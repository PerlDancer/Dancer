use Test::More tests => 4, import => ['!pass'];

$ENV{COOKIE} = "test_cookie=42";

use Dancer::Cookies;
ok(Dancer::Cookies->init, "Dancer::Cookies->init");

is_deeply(Dancer::Cookies->cookies, { 
    test_cookie => bless { 
        name => 'test_cookie', 
        value => 42,
        path => '/'}, 'Dancer::Cookie'}, 
    "cookies look good");

ok(! Dancer::Cookies->has_changed({name => 'test_cookie', value => 42}), 
    "cookie did not change");

ok(Dancer::Cookies->has_changed({name => 'test_cookie', value => 43}), 
    "cookie changed");

