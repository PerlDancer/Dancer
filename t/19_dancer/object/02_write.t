use strict;
use warnings;
use Test::More tests => 6;
use File::Temp;
use File::Spec::Functions;
use Dancer::Script;

my $dir = File::Temp->newdir();
my $tmpdir = $dir->dirname;
my $template = { 'test' => 'testing', };  
my $script = Dancer::Script->init(appname => 'Hello', path => $tmpdir, check_version => '1');
my $dancer_app_dir = $script->{dancer_app_dir};

#tests for short name.

# TODO-to-every-t: Supress the print messages from the *print* outputs. 
ok( $script->_safe_mkdir($dancer_app_dir),"safe_mkdir method sucessfully wrote a directory.");

ok( $script->run,"successfully created a full Dancer app.");

# write methods tests.
ok( $script->_write_bg(catfile($dancer_app_dir, 'public', 'images', 'perldancer-bg.jpg')),
"write_data_to_file method sucessfully wrote a file.");

ok( $script->_write_file(catfile($dancer_app_dir,'t','test'),$template), "write_file successfully writes a file.");

$script = Dancer::Script->init(appname => 'Hello::World', path => $tmpdir, check_version => '1');
$dancer_app_dir = $script->{dancer_app_dir};

#tests for long name.

# TODO-to-every-t: Supress the print messages from the *print* outputs. 
ok( $script->_safe_mkdir($dancer_app_dir),"safe_mkdir method sucessfully wrote a long name directory.");

ok( $script->run,"successfully created a full Dancer app with a long name.");
