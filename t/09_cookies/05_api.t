use Test::More tests => 1, import => ['!pass'];
use Dancer;
is_deeply(cookies, {}, "cookies() return a hashref");
