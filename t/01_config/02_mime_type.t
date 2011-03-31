use strict;
use warnings;

use Test::More tests => 7, import => ['!pass'];

use Dancer ':syntax';

BEGIN {
    use_ok 'Dancer::MIME';
}

my $mime = Dancer::MIME->instance();
is($mime->for_alias('svg'), 'image/svg+xml', 'mime type svg is known');

is_deeply($mime->aliases, {}, 'user defined mime_types are empty');

$mime->add_type(foo => 'text/foo');
is_deeply($mime->aliases, {foo => 'text/foo'}, 'text/foo is saved');
is($mime->for_alias('foo'), 'text/foo', 'mime type foo is found');

$mime->add_alias(bar => 'foo');
is($mime->for_alias('bar'), 'text/foo', 'mime type bar is found');

is($mime->for_file('foo.bar'), 'text/foo', 'mime type for extension .bar is found');

