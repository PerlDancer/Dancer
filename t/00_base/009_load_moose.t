use strict;
use warnings;

use Test::More tests => 2, import => ['!pass'];

BEGIN {
    use_ok( 'Dancer',         ':moose' );
}

ok( ! setting('appdir'), 'Moose import implies Syntax import' );
