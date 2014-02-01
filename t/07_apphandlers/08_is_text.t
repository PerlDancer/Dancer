use strict;
use warnings;

use Test::More tests => 5;

use Dancer::Handler;

for ( 'text/xml', 'text/html', 'text/javascript', 'text/json' ) {
    ok Dancer::Handler::_is_text($_), $_;
}

# see issue #994
for ( 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ) {
    ok !Dancer::Handler::_is_text($_), $_;
}


