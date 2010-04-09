use Test::More;
use strict;
use warnings;

plan tests => 6;
use Dancer::Timer;

my $timer = Dancer::Timer->new;
ok(defined($timer), "timer is defined");
isa_ok($timer, 'Dancer::Object');
isa_ok($timer, 'Dancer::Timer');
can_ok($timer, 'tick');
ok(defined($timer->start_time), "start_time is defined");
sleep 1;
ok(($timer->tick > 1), "tick has been increased: ".$timer->tick);

