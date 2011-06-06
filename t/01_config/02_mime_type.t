use strict;
use warnings;

use Test::More tests => 10, import => ['!pass'];

use Dancer ':syntax';

BEGIN {
    use_ok 'Dancer::MIME';
}

my $mime = Dancer::MIME->instance();
is($mime->for_name('svg'), 'image/svg+xml', 'mime type svg is known');

is_deeply($mime->custom_types, {}, 'user defined mime_types are empty');

$mime->add_type(foo => 'text/foo');
is_deeply($mime->custom_types, {foo => 'text/foo'}, 'text/foo is saved');
is($mime->for_name('foo'), 'text/foo', 'mime type foo is found');

$mime->add_alias(bar => 'foo');
is($mime->for_name('bar'), 'text/foo', 'mime type bar is found');

is($mime->for_file('foo.bar'), 'text/foo', 'mime type for extension .bar is found');

is($mime->add_alias(xpto => 'BAR'), 'text/foo', 'mime gets correctly lowercased for user types');

is($mime->add_alias(xpto => 'SVG'), 'image/svg+xml', 'mime gets correctly lowercased for system types');

is($mime->add_alias(zbr => 'baz'), $mime->default, 'alias of unkown mime type gets default mime type');
