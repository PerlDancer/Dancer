use Test::More import => ['!pass'];
use lib 't';
use TestUtils;

use Dancer;

get '/' => sub {
    "hello"
};

get '/failed' => sub {
    status 'not_found';
    "not here";
};

my @tests = (
    { path => '/', expected => undef},
    { path => '/failed', expected => 'not_found'},
    { path => '/', expected => undef},
    { path => '/failed', expected => 'not_found'},
);

plan tests => scalar(@tests) * 2;

foreach my $test (@tests) {
    my $cgi = fake_request(GET => $test->{path});
    Dancer::SharedData->cgi($cgi);
    my $response = Dancer::Renderer::get_action_response();

    ok(defined($response), "route handler found for ".$test->{path});
    is($response->{head}{status}, 
        $test->{expected}, 
        "status looks good for ".$test->{path}); 
}

