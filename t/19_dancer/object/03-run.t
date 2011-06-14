use strict;
use warnings;
use Test::More tests => 4;
use File::Temp;
use File::Spec::Functions;
use Dancer::Script;

my $dir = File::Temp->newdir();
my $tmpdir = $dir->dirname;
my $script = Dancer::Script->new(appname => 'Hello', path => $tmpdir, check_version => '1');

#tests
# TODO: Supress the print messages from the *print* outputs. 
can_ok( $script, 'run');

# -new->run() write test.
ok( $script->run,"successfully created a full Dancer app.");








