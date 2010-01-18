use strict;
use warnings;

use Test::More import => ['!pass'];
use lib 't';
use TestUtils;

BEGIN {
    use_ok 'Dancer';
    use_ok 'Dancer::Route';
};

{
    ok( get( '/', { agent => 'foo' } => sub {'agent foo'} ),
        'first route with options set' );
    ok( get( '/', sub {'all agents'} ), 'second route with options set' );
    ok( get( '/foo', { agent => 'foo' } => sub {'foo only'} ),
        'third route set' );
}

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
);

foreach my $test (@tests) {
    my $response = do_request($test);

    ok( defined $response,
        "route handler found for path `".$test->{path}."'");

    my $expected = $test->{expected};
    like( $response->{content}, qr/$expected/, "matching response looks good: ");
}

my $response = do_request({method => 'GET', path => '/foo', agent => 'bar'});
ok (!defined $response, "no route for foo with useragent bar");

sub do_request {
    my $test = shift;
    my $request = TestUtils::fake_request($test->{method} => $test->{path});
    $request->{user_agent} = $test->{agent};

    Dancer::SharedData->request($request);
    my $response = Dancer::Renderer::get_action_response();
}

done_testing();
