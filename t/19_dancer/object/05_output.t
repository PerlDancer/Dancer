use strict;
use warnings;
use Test::More;

use Dancer::ModuleLoader;
use Dancer::Script;
use File::Temp;
use File::Spec::Functions;

plan skip_all => "Test::Output is needed for this test"
    unless Dancer::ModuleLoader->load('Test::Output');

plan tests => 5;

use_ok 'Dancer::Logger::Console';

my $dir = File::Temp->newdir();
my $tmpdir = $dir->dirname;
my $template = { 'test' => 'testing', };  
my $script = Dancer::Script->init(appname => 'Hello', path => $tmpdir, check_version => '1');
my $dancer_app_dir = $script->{dancer_app_dir};


Test::Output::stderr_like( sub { $script->_safe_mkdir($dancer_app_dir)},
    qr/debug> */,
    "debug outputs correctly while writing a dir.");

Test::Output::stderr_like( sub { $script->run },
    qr/debug> */,
    "debug outputs correctly");

Test::Output::stderr_like( sub { $script->_write_bg(catfile($dancer_app_dir, 'public', 'images', 'perldancer-bg.jpg')) },
    qr/debug> */,
    "debug outputs correctly while writing a binary data file.");

Test::Output::stderr_like( sub { $script->_write_file(catfile($dancer_app_dir,'t','test'),$template)},
    qr/debug> */,
    "debug outputs correctly while writing a file.");
