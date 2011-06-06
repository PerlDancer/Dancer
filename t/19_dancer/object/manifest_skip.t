use strict;
use warnings;
use Test::More tests => 2; 
use Dancer::Script;

my $script = Dancer::Script->new(appname => 'Hello', path => '.', check_version => '1');
my $skip = $script->manifest_skip;

ok ( defined $skip, 'manifest_skip returns a string.');
ok ( $skip =~ m/\.git/i, 'Skip items identified.');
