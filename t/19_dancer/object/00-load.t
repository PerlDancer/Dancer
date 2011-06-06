use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Script' ) || print "Bail out!
";
}

diag( "Testing Dancer::Script Dancer: $Dancer::VERSION, Perl $], $^X" );
