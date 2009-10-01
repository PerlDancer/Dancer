use strict;
use warnings;

use Test::More tests => 7, import => ['!pass'];

BEGIN {
    use_ok 'Dancer';
    use_ok 'Dancer::FileUtils';
    use_ok 'Dancer::Config', 'setting', 'mime_types';
}

is_deeply(mime_types, Dancer::FileUtils->mime_types, 
    'mime_types are initialized');

ok(mime_types(foo => 'text/foo'), 'define text/foo');
is_deeply(mime_types, {%{Dancer::FileUtils->mime_types}, foo => 'text/foo'}, 'text/foo is saved');

is(mime_types('foo'), 'text/foo', 'mime type foo is found');
