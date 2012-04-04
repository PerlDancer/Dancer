use strict;
use warnings;

use Test::More;

use Dancer qw(:syntax);

is (int(dancer_version), 1, "dancer major version");

done_testing;
