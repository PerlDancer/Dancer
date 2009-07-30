use Test::More import => ['!pass'];
use lib 't';
use TestUtils;
use Dancer;

get '/' => sub {
    "hello"
};

get '/text' => sub {
    content_type 'text/plain';
    "text";
};

my @tests = (
    { path => '/', expected => undef},
    { path => '/text', expected => 'text/plain'},
    { path => '/', expected => undef},
    { path => '/text', expected => 'text/plain'},
);

plan tests => scalar(@tests) * 2;

foreach my $test (@tests) {
    my $cgi = fake_request(GET => $test->{path});
    Dancer::SharedData->cgi($cgi);
    my $response = Dancer::Renderer::get_action_response();

    ok(defined($response), "route handler found for ".$test->{path});
    is($response->{head}{content_type}, 
        $test->{expected}, 
        "content_type looks good for ".$test->{path}); 
}

