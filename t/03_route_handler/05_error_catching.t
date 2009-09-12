use Test::More import => ['!pass'];

use lib 't';
use TestUtils;

use Dancer;

get '/error' => sub {
	template('error');
};

get '/warning' => sub {
	my $bar;
    return "hello $bar";
};

get '/clean' => sub {
    "working"
};

my @tests = (
    { path => '/clean', expected => qr/working/ },
	{ path => '/error', 
	  expected => qr/Runtime Error: Can't locate object method "new" via package "Template"/m}, 
    { path => '/clean', expected => qr/working/ },
	{ path => '/warning', 
	  expected => qr/Runtime Warning: Use of uninitialized value .*in concatenation/},
    { path => '/clean', expected => qr/working/ },
);

plan tests => scalar(@tests);

foreach my $test (@tests) {
	my $req = fake_request(GET => $test->{path});
	Dancer::SharedData->cgi($req);

	my $response = Dancer::Renderer::get_action_response();
	like($response->{body}, 
		$test->{expected}, 
		"response looks good for ".$test->{path});
}
