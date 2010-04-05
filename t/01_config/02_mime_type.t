use strict;
use warnings;

use Test::More tests => 5, import => ['!pass'];

use Dancer ':syntax';

BEGIN {
    use_ok 'Dancer::Config', 'setting', 'mime_types';
}

is_deeply(mime_types, {}, 'user defined mime_types are empty');

ok(mime_types(foo => 'text/foo'), 'define text/foo');
is_deeply(mime_types, {foo => 'text/foo'}, 'text/foo is saved');

is(mime_types('foo'), 'text/foo', 'mime type foo is found');
