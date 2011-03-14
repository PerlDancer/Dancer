use Test::More import => ['!pass'];

my @keywords = (qw/before after pass/);

use Dancer ':moose', ':tests';

plan tests => scalar(@keywords) + 2;

foreach my $symbol (@keywords) {
    ok( !exists( $::{$symbol} ), "symbol `$symbol' is not exported" );
}

ok(exists($::{'get'}), "symbol `get' is exported");

use Cwd;
is setting("appdir"), path( getcwd, dirname(__FILE__) ), "app was still set up";

