use Test::More import => ['!pass'];

BEGIN {
    use Dancer::ModuleLoader;

    plan skip_all => "Template is needed to run this tests"
        unless Dancer::ModuleLoader->load('Template');
};

use Dancer ':syntax';
use t::lib::TestUtils;

set views => path(dirname(__FILE__), 'views');

my @tests = (
    { path => '/solo',
      expected => "view\n" },
    { path => '/full',
      expected => "start\nview\nstop\n" },
    { path => '/nolayout',
      expected => "view\n"},
    { path => '/customlayout',
      expected => "it's view\n different!"},
);

plan tests => scalar(@tests);

SKIP: {
    Template->import;

    get '/solo' => sub {
        template 't03';
    };

    get '/full' => sub {
        layout 'main';
        template 't03';
    };

    get '/nolayout' => sub {
        layout 'main';
        template 't03', {}, {layout => undef};
    };

    get '/customlayout' => sub {
        template 't03', {}, {layout => 'custom'};
    };

    foreach my $test (@tests) {
        my $path = $test->{path};
        my $expected = $test->{expected};

        my $request = fake_request(GET => $path);

        Dancer::SharedData->request($request);
        my $resp = Dancer::Renderer::get_action_response();

        is($resp->{content}, $expected, "content rendered looks good for $path");
    }
};
