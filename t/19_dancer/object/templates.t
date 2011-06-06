use strict;
use warnings;
use Test::More tests => 1; 
use Dancer::Script;

my $script = Dancer::Script->new(appname => 'Hello', path => '.', check_version => '1');
my $templates = $script->templates;

ok ( defined $templates, 'templates method returns a list.');
