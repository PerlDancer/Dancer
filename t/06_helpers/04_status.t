use Test::More import => ['!pass'];
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;

use Dancer ':syntax';

get '/' => sub {
    "hello"
};

get '/not_found' => sub {
    status 'not_found';
    "not here";
};

get '/500' => sub { status 500 };

my @tests = (
    { path => '/', expected => 200},
    { path => '/not_found', expected => 404},
    { path => '/500' => expected => 500 },
);

plan tests => scalar(@tests) * 2;

foreach my $test (@tests) {
    my $request = fake_request(GET => $test->{path});
    Dancer::SharedData->request($request);
    my $response = Dancer::Renderer::get_action_response();

    ok(defined($response), "route handler found for ".$test->{path});
    is($response->{status}, 
        $test->{expected}, 
        "status looks good for ".$test->{path}); 
}

