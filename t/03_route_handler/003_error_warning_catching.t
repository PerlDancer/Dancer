use Test::More import => ['!pass'];

use lib 't';
use TestUtils;

use Dancer;

get '/error' => sub {
	template('error');
};

get '/warning' => sub {
	my $bar = 1 + "hello";
};

my @tests = (
	{ path => '/error', 
	  expected => qr/Can't locate object method "new" via package "Template"/m}, 
	{ path => '/warning', 
	  expected => qr/Argument "hello" isn't numeric in addition/},
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
