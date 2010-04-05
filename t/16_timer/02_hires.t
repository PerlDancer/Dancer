use Test::More;
use strict;
use warnings;

use Dancer::Timer;
use Dancer::ModuleLoader;

plan skip_all => "Time::HiRes is needed to run this test"
    unless Dancer::ModuleLoader->load('Time::HiRes');
plan tests => 7;

my $timer = Dancer::Timer->new;
ok(defined($timer), "timer is defined");
isa_ok($timer, 'Dancer::Object');
isa_ok($timer, 'Dancer::Timer');
can_ok($timer, 'tick');
is($timer->mode, 'hires', "timer is on mode 'hires'");

ok(defined($timer->start_time), "start_time is defined");
sleep 1;
ok(($timer->tick > 1), "tick has been increased: ".$timer->tick);

