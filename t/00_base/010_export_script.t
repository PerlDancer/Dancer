use Test::More import => ["!pass"];
use Dancer ':script';

plan tests => 2;

ok(exists($::{'get'}), "symbol `get' is exported");

use Cwd;
ok setting("appdir"), ":script with exports allow app setup";
