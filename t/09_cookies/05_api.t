use Test::More import => ['!pass'];
use Dancer ':syntax';

my @tests = (
    { name => 'foo', value => 42 },
    { name => 'msg', value => 'hello; world' },
);

plan tests => scalar (@tests * 4) + 6;

is_deeply(cookies, {}, "cookies() return a hashref");

foreach my $test (@tests) {
    ok(set_cookie($test->{name} => $test->{value}), "set_cookie");
    my $c = cookies->{$test->{name}};
    ok defined($c), "cookie found";
    is $c->name, $test->{name}, "name is ".$test->{value};
    is $c->value, $test->{value}, "value is ".$test->{value};
}

ok my $c = Dancer::Cookie->new(
    name  => 'complex',
    value => { token => 'foo', token_secret => 'bar' },
);

my $text = $c->to_header;
like $text, qr/complex=token&foo&token_secret&bar/;

my $env = {
    REQUEST_METHOD => 'GET',
    SCRIPT_NAME => '/',
    COOKIE => 'complex=token&foo&token_secret&bar',
};
my $request = Dancer::Request->new($env);
Dancer::SharedData->request($request);
ok(Dancer::Cookies->init, "Dancer::Cookies->init");

my $cookies = Dancer::Cookies->cookies;
my %values = $cookies->{complex}->value;
is $values{token}, 'foo';
is $values{token_secret}, 'bar';

