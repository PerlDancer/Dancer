use strict;
use warnings;

use Test::More import => ['!pass'];
use t::lib::TestUtils;

plan tests => 17;
use Dancer ':syntax';
use Dancer::Route;

{
    ok( get( '/', { agent => 'foo' } => sub {'agent foo'} ),
        'first route with options set' );
    ok( get( '/', sub {'all agents'} ), 'second route with options set' );
    ok( get( '/foo', { agent => 'foo' } => sub {'foo only'} ),
        'third route set' );
    ok( get('/welcome', {agent => 'Mozilla'} => sub { "hey Mozilla!" }),
        'mozilla only route');
    ok( get('/welcome' => sub { "hello" }),
        'welcome for all route');
}

eval { get '/fail', { false_option => 42 } => sub { } };
like $@, qr/Not a valid option for route matching: `false_option'/, 
    "only supported options are allowed";

my @tests = (
    { method => 'GET', path => '/', expected => 'agent foo', agent => 'foo' },
    {
        method   => 'GET',
        path     => '/',
        expected => 'all agents',
        agent    => 'bar'
    },
    {
        method   => 'GET',
        path     => '/foo',
        expected => 'foo only',
        agent    => 'foo'
    },
    {
        method   => 'GET',
        path     => '/welcome',
        expected => 'hey Mozilla!',
        agent    => 'Mozilla/5.0 (X11; U; Linux x86_64; fr; rv:1.9.1.5)'
    },
    {
        method   => 'GET',
        path     => '/welcome',
        expected => 'hello',
    },

);

foreach my $test (@tests) {
    my $response = do_request($test);

    ok(defined $response,
       "route handler found for path `". $test->{path});

    my $expected = $test->{expected};
    like( $response->{content}, qr/$expected/, 
        "matching response looks good: ".$response->{content});
}

my $response = do_request({method => 'GET', path => '/foo', agent => 'bar'});
ok (!defined $response, "no route for foo with useragent bar");

sub do_request {
    my $test = shift;
    $ENV{HTTP_USER_AGENT} = $test->{agent} || undef;
    my $request = t::lib::TestUtils::fake_request($test->{method} => $test->{path});
    Dancer::SharedData->request($request);
    my $response = Dancer::Renderer::get_action_response();
}

