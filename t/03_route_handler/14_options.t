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
    ok( get( '/', { agent => 'foo' } => sub {'index'} ),
        'first route with options set' );
    ok( get( '/fail', { agent => 'foo' } => sub {'index'} ),
        'second route with options set' );
}

my @tests = (
    {method => 'GET', path => '/', expected => 'index', agent => 'foo'},
    {method => 'GET', path => '/fail', expected => '403', agent => 'bar'},
);

foreach my $test (@tests) {
    my $request = TestUtils::fake_request($test->{method} => $test->{path});
    $request->{user_agent} = $test->{agent};

    Dancer::SharedData->request($request);
    my $response = Dancer::Renderer::get_action_response();

    ok( defined $response,
        "route handler found for path `".$test->{path}."'");

    my $expected = $test->{expected};
    like( $response->{content}, qr/$expected/, "matching response looks good: ");
}

done_testing();
