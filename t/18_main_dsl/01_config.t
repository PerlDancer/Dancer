use strict;
use warnings;

use Dancer;
use Test::More import => ['!pass'];
plan tests => 1;

set foo => 42;
is 42, config->{'foo'}, 'config works';
