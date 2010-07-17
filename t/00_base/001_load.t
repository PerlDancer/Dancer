use strict;
use warnings;

use Test::More tests => 2, import => ['!pass'];

BEGIN {
    use_ok( 'Dancer' );
}

ok( setting('appdir'), 'Complete import' );
