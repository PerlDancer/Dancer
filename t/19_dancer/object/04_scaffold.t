use strict;
use warnings;
use Test::More tests => 2;
use File::Temp;
use Dancer::Script;

my $dir = File::Temp->newdir();
my $tmpdir = $dir->dirname;
my $script = Dancer::Script->init(appname => 'Hello', path => $tmpdir, check_version => '1');

#tests
# TODO: Supress the print messages from the *print* outputs. 
can_ok( $script, 'run');
can_ok( $script, 'run_scaffold', '_run_scaffold_cgi', '_run_scaffold_fcgi', );


