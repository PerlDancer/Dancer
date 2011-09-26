use strict;
use warnings;

use Test::More tests => 26*2, import => ['!pass'];

use Dancer ':syntax';
use Dancer::Test;

{
    get '/'                           => sub { 'index' };
    get '/name/:name'                 => sub { params->{name} };
    get '/name/:name/:location'       => sub { params->{name} };
    get '/location/:location'         => sub { params->{location} };
    get '/location/:name/:location'   => sub { params->{location} };

    post '/name/:name'                => sub { params->{name} };
    post '/name/:name/:location'      => sub { params->{name} };
    post '/location/:location'        => sub { params->{location} };
    post '/location/:name/:location'  => sub { params->{location} };
}

my @tests = (
    {method => 'GET', path => '/',                expected => 'index'},

    {method => 'GET', path => '/name/bob',        expected => 'bob'},
    {method => 'GET', path => '/name/bill',       expected => 'bill'},
    {method => 'GET', path => '/name/bob',        expected => 'bob'},

    {method => 'GET', path => '/name/bob/paris',  expected => 'bob' },
    {method => 'GET', path => '/name/bob/dublin', expected => 'bob' },
    {method => 'GET', path => '/name/bob/paris',  expected => 'bob' },

    {method => 'GET', path => '/name/bill/paris',  expected => 'bill' },
    {method => 'GET', path => '/name/bill/dublin', expected => 'bill' },
    {method => 'GET', path => '/name/bill/paris',  expected => 'bill' },

    {method => 'GET', path => '/name/bob/paris',   expected => 'bob' },
    {method => 'GET', path => '/name/bob/dublin',  expected => 'bob' },
    {method => 'GET', path => '/name/bill/paris',  expected => 'bill' },
    {method => 'GET', path => '/name/bill/dublin', expected => 'bill' },

    {method => 'GET', path => '/location/paris',      expected => 'paris'},
    {method => 'GET', path => '/location/dublin',     expected => 'dublin'},
    {method => 'GET', path => '/location/paris',      expected => 'paris'},

    {method => 'GET', path => '/location/bob/paris',  expected => 'paris' },
    {method => 'GET', path => '/location/bob/dublin', expected => 'dublin' },
    {method => 'GET', path => '/location/bob/paris',  expected => 'paris' },

    {method => 'post', path => '/name/bob',       expected => 'bob'},
    {method => 'post', path => '/name/bob/paris', expected => 'bob' },
    {method => 'post', path => '/location/paris',     expected => 'paris'},
    {method => 'post', path => '/location/bob/paris', expected => 'paris' },
    {method => 'post', path => '/location/bob/dublin', expected => 'dublin' },
    {method => 'post', path => '/location/bob/paris', expected => 'paris' },
);

setting route_cache => 1;

foreach my $test (@tests) {
    my $method = $test->{method};
    my $path = $test->{path};
    my $expected = $test->{expected};

    my $request = [$method => $path];

    response_status_is $request => 200;
    response_content_is_deeply $request, $expected, 
}
