use strict;
use warnings;

use Test::More import => ['!pass'];

use Dancer qw(:syntax);

is (int(dancer_version), 1, "dancer major version");

done_testing;
