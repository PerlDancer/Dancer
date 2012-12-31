use strict;
use warnings;

use Test::More import => ['!pass'];

use Dancer qw(:syntax);

plan tests => 2;

is (int(dancer_version), 1, "dancer major version");

is dancer_api_version() => 1, 'dancer api version';
