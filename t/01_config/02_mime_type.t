use strict;
use warnings;

use Test::More tests => 6, import => ['!pass'];

BEGIN {
    use_ok 'Dancer';
    use_ok 'Dancer::Config', 'setting', 'mime_types';
}

is_deeply(mime_types, {}, 'user defined mime_types are empty');

ok(mime_types(foo => 'text/foo'), 'define text/foo');
is_deeply(mime_types, {foo => 'text/foo'}, 'text/foo is saved');

is(mime_types('foo'), 'text/foo', 'mime type foo is found');
