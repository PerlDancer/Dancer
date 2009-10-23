use Test::More tests => 7;

use strict;
use warnings;

use_ok 'Dancer::Response';

my $r = Dancer::Response->new;
is $r->{status}, 200, "status looks good";
is_deeply $r->{headers}, [], "headers look good";

is ref(Dancer::Response->current), 'Dancer::Response', 
    "->current returned an object";
Dancer::Response::status(500);
Dancer::Response::content_type("text/plain");
Dancer::Response::pass();

$r = Dancer::Response->current;
is($r->{status}, 500, "status looks good");
is($r->{content_type}, "text/plain", "content_type looks good");
is($r->{pass}, 1, "pass flag looks good");
