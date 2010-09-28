use strict;
use warnings;

use Test::More tests => 17, import => ['!pass'];
use Dancer::Test;

use Dancer ':syntax';
use Dancer::Route;
use Data::Dumper;

{
    ok(get('/' => sub { 'index' }), 'first route set');
    ok(get('/hello/:name' => sub { params->{name} }), 'second route set');
    ok(get('/hello/:foo/bar' => sub { params->{foo} }), 'third route set');
    ok(post('/new/:stuff' => sub { params->{stuff} }), 'post 1 route set');
    ok(post('/allo' => sub { request->body }), 'post 2 route set');
}

my @tests = (
    {method => 'GET', path => '/', expected => 'index'},
    {method => 'GET', path => '/hello/sukria', expected => 'sukria'},
    {method => 'GET', path => '/hello/joe/bar', expected => 'joe' },
    {method => 'POST', path => '/new/wine', expected => 'wine' },
);

foreach my $test (@tests) {
    my $req = [$test->{method}, $test->{path}];

    route_exists $req, 
        "route handler found for path `".$test->{path}."'";

    response_content_is $req, $test->{expected},
        "matching param looks good";

    # splat should not be set
    ok(!exists(params->{'splat'}), "splat not defined for ".$test->{path});
}
