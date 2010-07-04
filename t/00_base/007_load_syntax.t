use strict;
use warnings;

use Test::More tests => 2, import => ['!pass'];

BEGIN {
    use_ok( 'Dancer',         ':syntax' );
}

ok( ! setting('appdir'), 'Syntax import' );
