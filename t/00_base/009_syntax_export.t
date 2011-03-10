use Test::More import => ["!pass"];
use Dancer ':moose', ':tests', ":syntax";

my @keywords = (qw/before after pass/);

plan tests => scalar(@keywords) + 2;

foreach my $symbol (@keywords) {
    ok( !exists( $::{$symbol} ), "symbol `$symbol' is not exported" );
}

ok(exists($::{'get'}), "symbol `get' is exported");

use Cwd;
ok !setting("appdir"), ":syntax with exports prevents app setup";
