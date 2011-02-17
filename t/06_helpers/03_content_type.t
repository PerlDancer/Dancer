use Test::More import => ['!pass'];
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;
use Dancer ':syntax';

get '/' => sub {
    "hello"
};

get '/text' => sub {
    content_type 'text/plain';
    "text";
};

get '/svg' => sub {
    content_type 'svg';
    "<svg/>";
};

get '/png' => sub {
    content_type 'png';
    "blergh";
};


my @tests = (
    { path => '/',     expected => setting('content_type')},
    { path => '/text', expected => 'text/plain'},
    { path => '/',     expected => setting('content_type')},
    { path => '/text', expected => 'text/plain'},
    { path => '/svg',  expected => 'image/svg+xml'},
    { path => '/png',  expected => 'image/png'},
);

plan tests => scalar(@tests) * 2;

foreach my $test (@tests) {
    my $request = fake_request(GET => $test->{path});
    Dancer::SharedData->request($request);
    my $response = Dancer::Renderer::get_action_response();

    ok(defined($response), "route handler found for ".$test->{path});
    my %headers = @{$response->headers_to_array};
    is($headers{'Content-Type'}, 
        $test->{expected}, 
        "content_type looks good for ".$test->{path}); 
}

