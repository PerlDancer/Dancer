use strict;
use warnings;
use Test::More tests => 4;
use File::Temp;
use File::Spec::Functions;
use Dancer::Script;

my $dir = File::Temp->newdir();
my $tmpdir = $dir->dirname;
my $template = { 'test' => 'testing', };  
my $script = Dancer::Script->new(appname => 'Hello', path => $tmpdir, check_version => '1');
my $dancer_app_dir = $script->{dancer_app_dir};

#tests

# TODO-to-every-t: Supress the print messages from the *print* outputs. 
ok( $script->safe_mkdir($dancer_app_dir),"safe_mkdir method sucessfully wrote a directory.");

ok( $script->run,"successfully created a full Dancer app.");

ok( $script->write_bg(catfile($script->{path},$script->{appname}, 'public', 'images', 'perldancer-bg.jpg')),
"write_data_to_file method sucessfully wrote a file.");

ok( $script->write_file(catfile($script->{path},$script->{appname},'t','test'),$template), "write_file successfully writes a file.");







