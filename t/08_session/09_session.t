use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer::Session;

plan tests => 3;

my $session = Dancer::Session->init('Simple', {});
ok $session;

is_deeply($session, Dancer::Session->engine);

ok my $session_desc = Dancer::Session->get_current_session;
