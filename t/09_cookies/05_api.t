use Test::More tests => 5, import => ['!pass'];
use Dancer ':syntax';
is_deeply(cookies, {}, "cookies() return a hashref");

ok(set_cookie(foo => 42), "set_cookie");

my $c = cookies->{foo};
ok defined($c), "cookie found";
is $c->name, 'foo', 'name is foo';
is $c->value, 42, 'value is 42';
