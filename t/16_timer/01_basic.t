use Test::More tests => 7;
use strict;
use warnings;

# we don't want Time::HiRes to get loaded
use t::lib::EasyMocker;
mock 'Dancer::ModuleLoader'
    => method 'load'
    => should sub { 0 };

use Dancer::Timer;

my $timer = Dancer::Timer->new;
ok(defined($timer), "timer is defined");
isa_ok($timer, 'Dancer::Object');
isa_ok($timer, 'Dancer::Timer');
can_ok($timer, 'tick');
is($timer->mode, 'seconds', "timer is on mode 'seconds'");

ok(defined($timer->start_time), "start_time is defined");
sleep 1;
ok(($timer->tick > 0), "tick has been increased");

