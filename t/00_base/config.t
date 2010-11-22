use strict;
use warnings;
use Test::More import => ['!pass'];

plan tests => 1;

use Dancer;
use Dancer::Test;

setting foo => 42;

get '/' => sub { config };

my $res = dancer_response(GET => '/');
is $res->{content}{foo}, 42, "setting is accessible via config";

