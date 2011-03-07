use Test::More import => ['!pass'];

my @keywords = (qw/before after pass/);

use Dancer ':moose', ':tests';

plan tests => scalar(@keywords) + 1;

foreach my $symbol (@keywords) {
    ok( !exists( $::{$symbol} ), "symbol `$symbol' is not exported" );
}

ok(exists($::{'get'}), "symbol `get' is exported");
