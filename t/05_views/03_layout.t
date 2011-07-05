BEGIN {
    use Dancer ':tests';
    use Test::More;
    use Dancer::ModuleLoader;

    plan skip_all => "Template is needed to run this tests"
        unless Dancer::ModuleLoader->load('Template');
    plan skip_all => "YAML needed to run this tests"
        unless Dancer::ModuleLoader->load('YAML');
    plan skip_all => "File::Temp 0.22 required"
        unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );


    use File::Spec;
    use lib File::Spec->catdir( 't', 'lib' );
    use TestUtils;
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

plan tests => scalar(@tests) + 4;

my $dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
set appdir => $dir;
my $envdir = File::Spec->catdir($dir, 'environments');
mkdir $envdir;

my $conffile = Dancer::Config->conffile;
ok(defined($conffile),   'Default conffile is defined'       );
ok(Dancer::Config->load, 'Config load works without conffile');

# create the conffile
my $conf = '
layout: main
';

write_file( $conffile => $conf );
ok( Dancer::Config->load, 'Config load works with a conffile' );
is( setting('layout'), 'main', 'Correct layout setting from config' );

Template->import;

get '/solo' => sub {
    setting layout => undef;
    template 't03';
};

get '/full' => sub {
    set layout => 'main';
    template 't03';
};

get '/layoutdisabled' => sub {
    set layout => 'main';
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
    my $path     = $test->{path};
    my $expected = $test->{expected};
    response_content_is [ GET => $path ] => $expected;
}

unlink $conffile;
File::Temp::cleanup();
