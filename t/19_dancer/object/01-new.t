use strict;
use warnings;
use Test::More tests => 15;
use Dancer::Script;

use_ok( 'Dancer::Script' );
my $script = Dancer::Script->new(appname => 'Hello::World', path => '.', check_version => '1');
isa_ok( $script, 'Dancer::Script', );
can_ok( $script, 'parse_opts', 'validate_app_name', );
can_ok( $script, '_set_application_path', '_set_script_path', '_set_lib_path', );

isnt( $script->_dash_name, $script->{appname}, '_dash_name parses appname correctly.'); 

is( $script->{dancer_app_dir}, $script->{dancer_script}, "_set_application_path sets correctly ->{dancer_app_dir}");


my @lib_path = split('::', $script->{appname});
my ($lib_file, $lib_path) = (pop @lib_path) . ".pm";

is( $script->{lib_file}, $lib_file, "_set_lib_path sets correctly ->{lib_file} and ->{lib_path}");
is( $script->{lib_path}, $lib_path, "_set_lib_path sets correctly ->{lib_file} and ->{lib_path}");

is( $script->{dancer_script}, $script->_dash_name, "_set_script_path sets correctly ->{dancer_script}");

my $list = $script->app_tree;

ok (defined $list, 'app_tree successfully returns a list.');

my $jquery = $script->jquery_minified;

ok ( defined $jquery, 'jquery_minified returns a jquery code.');
ok ( $jquery =~ m/jQuery JavaScript Library/i, 'jQuery string identified.');

my $skip = $script->manifest_skip;

ok ( defined $skip, 'manifest_skip returns a string.');
ok ( $skip =~ m/\.git/i, 'Skip items identified.');

my $templates = $script->templates;

ok ( defined $templates, 'templates method returns a list.');
