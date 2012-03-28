use Test::More tests => 28, import => ['!pass'];
use strict;
use warnings;

use Dancer;
use Dancer::Logger::Abstract;

my @log_levels = qw(core debug info warning error);
my $l          = Dancer::Logger::Abstract->new;
isa_ok $l, 'Dancer::Logger::Abstract';
can_ok $l, (qw(_log _should), @log_levels);

eval { $l->_log };
like $@, qr/_log not implemented/, "_log is a virtual method";


my @implemented;

for my $level (0 .. $#log_levels) {
    set log => $log_levels[0];
    for my $levels (@log_levels) {
        eval { $l->$levels("foo") };
        like $@ => qr/not implemented/;
    }
    for my $levels (@implemented) {
        is($l->$levels("foo"), "");
    }
    push @implemented => shift @log_levels;
}
