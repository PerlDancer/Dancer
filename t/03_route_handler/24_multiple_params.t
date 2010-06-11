use strict;
use warnings;

use Test::More tests => 26*2+9, import => ['!pass'];

use t::lib::TestUtils;

use Dancer ':syntax';
use Dancer::Route;

use Dancer::Config 'setting';

{
    ok(get('/'                           => sub { 'index' }),            'first route set');
    ok(get('/name/:name'                 => sub { params->{name} }),     'second route set');
    ok(get('/name/:name/:location'       => sub { params->{name} }),     'third route set');
#    ok(get('/name/:name/:location/*'     => sub { [params->{name},splat] }),  'third route set');
    ok(get('/location/:location'         => sub { params->{location} }), 'fourth route set');
    ok(get('/location/:name/:location'   => sub { params->{location} }), 'fifth route set');
#    ok(get('/location/:name/:location/*' => sub { [params->{location},splat] }), 'fifth route set');
    ok(post('/name/:name'                => sub { params->{name} }),     'sixth route set');
    ok(post('/name/:name/:location'      => sub { params->{name} }),     'seventh route set');
    ok(post('/location/:location'        => sub { params->{location} }), 'eigth route set');
    ok(post('/location/:name/:location'  => sub { params->{location} }), 'ninth route set');
}

my @tests = (
    {method => 'GET', path => '/',                expected => 'index'},

    {method => 'GET', path => '/name/bob',        expected => 'bob'},
    {method => 'GET', path => '/name/bill',       expected => 'bill'},
    {method => 'GET', path => '/name/bob',        expected => 'bob'},

#    {method => 'GET', path => '/name/bob/paris/wine',  expected => ['bob','wine'] },
#    {method => 'GET', path => '/name/bob/dublin/beer', expected => ['bob','beer'] },
#    {method => 'GET', path => '/name/bob/paris/wine',  expected => ['bob','wine'] },

#    {method => 'GET', path => '/name/bill/paris/wine',  expected => ['bill','wine'] },
#    {method => 'GET', path => '/name/bill/dublin/beer', expected => ['bill','beer'] },
#    {method => 'GET', path => '/name/bill/paris/wine',  expected => ['bill','wine'] },

#    {method => 'GET', path => '/name/bob/paris/today',     expected => ['bob','today'] },
#    {method => 'GET', path => '/name/bob/dublin/now',      expected => ['bob','now'] },
#    {method => 'GET', path => '/name/bob/paris/tomorrow',  expected => ['bob','tomorrow'] },

    {method => 'GET', path => '/name/bob/paris',  expected => 'bob' },
    {method => 'GET', path => '/name/bob/dublin', expected => 'bob' },
    {method => 'GET', path => '/name/bob/paris',  expected => 'bob' },

    {method => 'GET', path => '/name/bill/paris',  expected => 'bill' },
    {method => 'GET', path => '/name/bill/dublin', expected => 'bill' },
    {method => 'GET', path => '/name/bill/paris',  expected => 'bill' },

    {method => 'GET', path => '/name/bob/paris',  expected => 'bob' },
    {method => 'GET', path => '/name/bob/dublin', expected => 'bob' },
    {method => 'GET', path => '/name/bill/paris',  expected => 'bill' },
    {method => 'GET', path => '/name/bill/dublin', expected => 'bill' },

    {method => 'GET', path => '/location/paris',      expected => 'paris'},
    {method => 'GET', path => '/location/dublin',     expected => 'dublin'},
    {method => 'GET', path => '/location/paris',      expected => 'paris'},

    {method => 'GET', path => '/location/bob/paris',  expected => 'paris' },
    {method => 'GET', path => '/location/bob/dublin', expected => 'dublin' },
    {method => 'GET', path => '/location/bob/paris',  expected => 'paris' },

#    {method => 'GET', path => '/location/bob/paris/wine',  expected => ['paris','wine'] },
#    {method => 'GET', path => '/location/bob/dublin/beer', expected => ['dublin','beer'] },
#    {method => 'GET', path => '/location/bob/paris/wine',  expected => ['paris','wine'] },

    {method => 'post', path => '/name/bob',       expected => 'bob'},
    {method => 'post', path => '/name/bob/paris', expected => 'bob' },
    {method => 'post', path => '/location/paris',     expected => 'paris'},
    {method => 'post', path => '/location/bob/paris', expected => 'paris' },
    {method => 'post', path => '/location/bob/dublin', expected => 'dublin' },
    {method => 'post', path => '/location/bob/paris', expected => 'paris' },
);

setting route_cache => 1;

foreach my $test (@tests) {
    #use Data::Dumper; diag("TEST DATA: " . Dumper $test);
    my $method = $test->{method};
    my $path = $test->{path};
    my $expected = $test->{expected};

    my $request = fake_request($method => $path);

    Dancer::SharedData->request($request);
    my $response = Dancer::Renderer::get_action_response();
    
    ok( defined($response), "route handler found for path `$path'");
    is_deeply(
        $response->{content}, $expected, 
        "match data for path `$path' looks good");

}
