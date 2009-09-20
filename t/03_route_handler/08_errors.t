use Test::More 'no_plan', import => ['!pass'];

use strict;
use warnings;

use Dancer::Error;

my $error = Dancer::Error->new(code => 500);
ok(defined($error), "error is defined");
ok($error->title, "title is set");
