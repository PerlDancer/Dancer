use Test::More import => ['!pass'];
use Dancer ':syntax';

my @tests = (
    { name => 'foo', value => 42 ,            opts => {}},
    { name => 'foo', value => 42 ,            opts => { http_only => 1 } },
    { name => 'msg', value => 'hello; world', opts => {} },
    { name => 'msg', value => 'hello; world', opts => { http_only => 0 } },
);

plan tests => scalar (@tests * 5) + 12;

is_deeply(cookies, {}, "cookies() return a hashref");

foreach my $test (@tests) {
    ok(set_cookie($test->{name} => $test->{value}, %{$test->{opts}}), "set_cookie");
    my $c = cookies->{$test->{name}};
    ok defined($c), "cookie found";
    is $c->name, $test->{name}, "name is ".$test->{value};
    is $c->value, $test->{value}, "value is ".$test->{value};
    is $c->http_only,
       (exists($test->{opts}{http_only}) ? $test->{opts}{http_only} : undef),
       "HttpOnly is correctly set";
}

{
    my $values = { token => 'foo', token_secret => 'bar' };

    ok my $c = Dancer::Cookie->new(
        name  => 'complex',
        value => $values,
    );

    subtest "cookie header" => sub {
        plan tests => 2;

        ok $c->to_header =~ /^complex=([^;]+);/, "cookie name";

        my %cookie_values = split '&', $1;

        is_deeply \%cookie_values => $values, "cookie values";
    };
}

my $env = {
    REQUEST_METHOD => 'GET',
    SCRIPT_NAME => '/',
    COOKIE => 'complex=token&foo&token_secret&bar',
};
my $request = Dancer::Request->new(env => $env);
Dancer::SharedData->request($request);
ok(Dancer::Cookies->init, "Dancer::Cookies->init");

my $cookies = Dancer::Cookies->cookies;
my %values = $cookies->{complex}->value;
is $values{token}, 'foo';
is $values{token_secret}, 'bar';

is cookie(answer => 42, path => 'dtc'), 42, "cookie set";
is cookie('answer'), 42, "cookie get";
is cookies->{answer}->path, 'dtc', "cookie option correctly set";
is cookie('zorglub'), undef, "unknown cookie";

### test for im0
$env = {
    REQUEST_METHOD => 'GET',
    SCRIPT_NAME => '/',
    HTTP_COOKIE => 'dancer.session=1209039; fbs_102="access_token=xxxxxxxxxx%7Cffffff"',
};

$request = Dancer::Request->new(env => $env);
Dancer::SharedData->request($request);
Dancer::Cookies->init;

$cookies = Dancer::Cookies->cookies;
like $cookies->{fbs_102}->value, qr/access_token\=/;

# Test for undef cookie values from technically invalid cookies issue #782
eval {
    use warnings FATAL => qw( all );

    $env = {
        REQUEST_METHOD => 'GET',
        SCRIPT_NAME => '/',
        HTTP_COOKIE => 'invalid_cookie=1,2,3',
    };

    $request = Dancer::Request->new(env => $env);
    Dancer::SharedData->request($request);
    Dancer::Cookies->init;
};
unlike($@, qr/Use of uninitialized value in string/, 'undef or invalid cookies are quietly ignored');

