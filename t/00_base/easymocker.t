use Test::More tests => 3;
use strict;
use warnings;

use Dancer qw(:tests);

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use EasyMocker;


ok(
    Dancer->true,
    "Before mocking, get true",
);
mock 'Dancer'
    => method 'true'
    => should sub { 0 };

ok(
    !Dancer->true,
    "Mocked, get false",
);

unmock 'Dancer' => method 'true';

ok(
    Dancer->true,
    "Unmocked, get true again",
);

