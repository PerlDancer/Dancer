use Test::More import => ['!pass'];

use lib 't';
use TestUtils;
use Dancer;

# Perl 5.10 does not detect constant folding warnings
# in the compilation phase
sub perl_has_constant_folding_bug {
    foreach my $v qw(5.01000) {
        return 1 if $] == $v;
    }
    return 0;
}

get '/warning' => sub {
	my $bar = 1 + "hello";
};

# Perl 5.10.0 is buggy there, so don't break the test suite if ran under it
plan skip_all => "test cannot run under Perl $]" 
    if perl_has_constant_folding_bug;

my @tests = (
    { path => '/warning', 
	  expected => qr/Compilation warning: Argument "hello" isn't numeric in addition/},
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
