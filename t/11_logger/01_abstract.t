use Test::More tests => 23, import => ['!pass'];
use strict;
use warnings;

use Dancer;

use t::lib::EasyMocker;

use_ok 'Dancer::Logger::Abstract';

my $l = Dancer::Logger::Abstract->new;
isa_ok $l, 'Dancer::Logger::Abstract';
can_ok $l, (qw(_log _should debug warning error));

foreach my $method (qw(_log debug warning error)) {
    eval { $l->$method };
    like $@, qr/_log not implemented/, "$method is a virtual method";
}


# core
setting log => 'core';
ok $l->_should('core'), "core level accepted";
ok $l->_should('debug'), "debug level accepted";
ok $l->_should('warning'), "warning level accepted";
ok $l->_should('error'), "error level accepted";

# debug
setting log => 'debug';
ok !$l->_should('core'), "core level not accepted";
ok $l->_should('debug'), "debug level accepted";
ok $l->_should('warning'), "warning level accepted";
ok $l->_should('error'), "error level accepted";

setting log => 'warning';
ok !$l->_should('core'), "core level not accepted";
ok !$l->_should('debug'), "debug level not accepted";
ok $l->_should('warning'), "warning level accepted";
ok $l->_should('error'), "error level accepted";

setting log => 'error';
ok !$l->_should('core'), "core level not accepted";
ok !$l->_should('debug'), "debug level not accepted";
ok !$l->_should('warning'), "warning level not accepted";
ok $l->_should('error'), "error level accepted";

