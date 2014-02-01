use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer::Session;
use Dancer::Cookies;

plan tests => 6;

my $session = Dancer::Session->init('Simple', {});
ok $session;

is_deeply($session, Dancer::Session->engine);

my $desc = Dancer::Session->get_current_session;
ok $desc;
ok( Dancer::Cookies->cookies->{'dancer.session'} );

# remove this
delete Dancer::Cookies->cookies->{'dancer.session'};

# after this no cookie should get set
ok( Dancer::Session->get_current_session( no_update => 1 ) );

# no session cookie for you!
ok !exists Dancer::Cookies->cookies->{'dancer.session'};
