use Test::More import => ['!pass'];

use t::lib::TestUtils;
use Dancer ':syntax';

use Dancer::Logger;
use File::Temp qw/tempdir/;

my $dir = tempdir(CLEAN_UP => 1);
set appdir => $dir;
Dancer::Logger->init('File');

get '/error' => sub {
    Foo->bar;
};

get '/warning' => sub {
	my $bar;
    return "hello $bar";
};

get '/clean' => sub {
    "working"
};

set warnings => 1;

my @hidden_errors = (
    { path => '/clean', expected => qr/working/ },
	{ path => '/error', 
	  expected => qr/Unable to process your query.*The page you requested is not available/m}, 
    { path => '/clean', expected => qr/working/ },
	{ path => '/warning', 
	  expected => qr/Unable to process your query.*The page you requested is not available/m}, 
    { path => '/clean', expected => qr/working/ },
);

my @visible_errors = (
    { path => '/clean', expected => qr/working/ },
	{ path => '/error', 
	  expected => qr/Can't locate object method "bar" via package "Foo"/m}, 
    { path => '/clean', expected => qr/working/ },
	{ path => '/warning', 
	  expected => qr/Use of uninitialized value .*in concatenation/},
    { path => '/clean', expected => qr/working/ },
);

plan tests => scalar(@hidden_errors) + scalar(@visible_errors);

set show_errors => 0;
foreach my $test (@hidden_errors) {
	my $req = fake_request(GET => $test->{path});
	Dancer::SharedData->request($req);

	my $response = Dancer::Renderer::get_action_response();
	like($response->{content}, 
		$test->{expected}, 
		"response looks good for hidden error ".$test->{path});
}

set show_errors => 1;
foreach my $test (@visible_errors) {
	my $req = fake_request(GET => $test->{path});
	Dancer::SharedData->request($req);

	my $response = Dancer::Renderer::get_action_response();
	like($response->{content}, 
		$test->{expected}, 
		"response looks good for visible error ".$test->{path});
}

