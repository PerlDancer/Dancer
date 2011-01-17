use Test::More import => ['!pass'];
use Dancer ':syntax';

my @tests = (
    { name => 'foo', value => 42 },
    { name => 'msg', value => 'hello; world' },
);

plan tests => scalar (@tests * 4) + 1;

is_deeply(cookies, {}, "cookies() return a hashref");

foreach my $test (@tests) {
    ok(set_cookie($test->{name} => $test->{value}), "set_cookie");
    my $c = cookies->{$test->{name}};
    ok defined($c), "cookie found";
    is $c->name, $test->{name}, "name is ".$test->{value};
    is $c->value, $test->{value}, "value is ".$test->{value};
}
