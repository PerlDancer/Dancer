use strict;
use warnings;
use Test::More import => ['!pass'];

plan tests => 3;

use Dancer;
use Dancer::Test;

set foo => 42;

get '/' => sub { config };

my $res = dancer_response(GET => '/');
is $res->{content}{foo}, 42, "setting is accessible via config";

is config->{'foo'}, 42, "config works";

is setting('foo'), 42, "setting works";
