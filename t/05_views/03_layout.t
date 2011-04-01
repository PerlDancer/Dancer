BEGIN {
    use Dancer ':tests';
    use Test::More;
    use Dancer::ModuleLoader;

    plan skip_all => "Template is needed to run this tests"
        unless Dancer::ModuleLoader->load('Template');
};

use Dancer::Test;

set views => path(dirname(__FILE__), 'views');

my @tests = (
    { path => '/solo',
      expected => "view\n" },
    { path => '/full',
      expected => "start\nview\nstop\n" },
    { path => '/layoutdisabled',
      expected => "view\n" },
    { path => '/layoutchanged',
      expected => "customstart\nview\ncustomstop\n" },
    { path => '/render_layout_only/default_layout',
      expected => "start\ncontent\nstop\n" },
    { path => '/render_layout_only/no_layout',
      expected => "content\n" },
    { path => '/render_layout_only/custom_layout',
      expected => "customstart\ncontent\ncustomstop\n" },
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

    get '/layoutdisabled' => sub {
        layout 'main';
        template 't03', {}, { layout => undef };
    };

    get '/layoutchanged' => sub {
        template 't03', {}, { layout => 'custom' };
    };

    get '/render_layout_only/default_layout' => sub {
        engine('template')->apply_layout("content\n");
    };

    # Yes, apply_layout without a layout is kind of pointless, but let's
    # be thorough :)
    get '/render_layout_only/no_layout' => sub {
        engine('template')->apply_layout("content\n", {}, { layout => undef });
    };

    get '/render_layout_only/custom_layout' => sub {
        engine('template')->apply_layout("content\n", {}, { layout => 'custom' });
    };

    foreach my $test (@tests) {
        my $path = $test->{path};
        my $expected = $test->{expected};

        my $resp = dancer_response(GET => $path);
        is($resp->content, $expected, "content rendered looks good for $path");
    }
}; 
