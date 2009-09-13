use Test::More import => ['!pass'];

use Dancer;
use lib 't';
use TestUtils;

my @tests = (
    { path => '/solo',
      expected => "view\n" },
    { path => '/full',
      expected => "start\nview\nstop\n" },
);

plan tests => scalar(@tests);

# we need Template to continue
eval "use Template";
SKIP: {
    skip "Template is required to test views", scalar(@tests) if $@;
    Template->import;
    
    get '/solo' => sub {
        template 't03';
    };

    get '/full' => sub {
        layout 'main';
        template 't03';
    };

    foreach my $test (@tests) {
        my $path = $test->{path};
        my $expected = $test->{expected};

        my $request = fake_request(GET => $path);

        Dancer::SharedData->cgi($request);
        my $resp = Dancer::Renderer::get_action_response();
    
        is($resp->{content}, $expected, "content rendered looks good for $path");
    }
}; 
