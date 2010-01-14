use strict;
use warnings;

use Test::More tests => 3, import => ['!pass'];

BEGIN {
    use_ok( 'Dancer',         ':syntax' );
    use_ok( 'Dancer::Config', 'setting' );
}

ok( ! setting('appdir'), 'Syntax import' );
