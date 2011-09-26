use Test::More tests => 20, import => ['!pass'];
use strict;
use warnings;

use Dancer;

use t::lib::EasyMocker;

use_ok 'Dancer::Logger::Abstract';

my $l = Dancer::Logger::Abstract->new;
isa_ok $l, 'Dancer::Logger::Abstract';
can_ok $l, (qw(_log _should debug warning error));

eval { $l->_log };
like $@, qr/_log not implemented/, "_log is a virtual method";


# core log level
set log => 'core';
for my $levels (qw{core debug warning error}) {
    eval { $l->$levels("foo") };
    like $@ => qr/not implemented/;
}

# debug log level
set log => 'debug';
for my $levels (qw{debug warning error}) {
    eval { $l->$levels("foo") };
    like $@ => qr/not implemented/;
}
for my $levels (qw{core}) {
    is ($l->$levels("foo"), "");
}

# warning log level
set log => 'warning';
for my $levels (qw{warning error}) {
    eval { $l->$levels("foo") };
    like $@ => qr/not implemented/;
}
for my $levels (qw{core debug}) {
    is ($l->$levels("foo"), "");
}

# error log level
set log => 'error';
for my $levels (qw{error}) {
    eval { $l->$levels("foo") };
    like $@ => qr/not implemented/;
}
for my $levels (qw{core debug warning}) {
    is ($l->$levels("foo"), "");
}

