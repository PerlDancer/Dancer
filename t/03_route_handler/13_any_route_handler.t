use Test::More tests => 16, import => ['!pass'];
use lib 't';
use TestUtils;

use Dancer;

ok( any(['get', 'delete'] => '/any_1' => sub { 
    "any_1"
}), 
"route defined for 'get' and 'delete' methods for /any_1" );

ok( any('/any_2' => sub { 
    "any_2"
}), 
"route defined for any methods for /any_2" );

my @routes = (
    {
        methods => ['get', 'delete'],
        path => '/any_1',
        expected => 'any_1',
    },
    {
        methods => ['get', 'delete', 'post', 'put'],
        path => '/any_2',
        expected => 'any_2',
    }
);

# making sure response are OK
foreach my $route (@routes) {
    foreach my $method (@{ $route->{methods} }) {
        my $cgi = TestUtils::fake_request($method => $route->{path});
        Dancer::SharedData->cgi($cgi);
        my $response = Dancer::Renderer::get_action_response();
        ok(defined($response), 
            "route handler found for method $method, path ".$route->{path});
        is $response->{content}, $route->{expected}, "response content is ok";
    }
}

# making sure 404 are thrown for unspecified routes
my @failed = (
    {
        methods => ['post', 'put'],
        path => '/any_1',
    },
);

foreach my $route (@failed) {
    foreach my $method (@{ $route->{methods} }) {
        my $cgi = TestUtils::fake_request($method => $route->{path});
        Dancer::SharedData->cgi($cgi);
        my $response = Dancer::Renderer::get_action_response();
        ok(!defined($response), 
            "route handler not found for method $method, path ".$route->{path});
    }
}
