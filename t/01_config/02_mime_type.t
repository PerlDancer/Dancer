use strict;
use warnings;

use Test::More tests => 11, import => ['!pass'];

use Dancer ':syntax';

BEGIN {
    use_ok 'Dancer::MIME';
}

my $mime = Dancer::MIME->instance();
is($mime->mime_type_for('svg'), 'image/svg+xml', 'mime type svg is known');

is_deeply($mime->aliases, {}, 'user defined mime_types are empty');

ok($mime->add_mime_type(foo => 'text/foo'), 'define text/foo');
is_deeply($mime->aliases, {foo => 'text/foo'}, 'text/foo is saved');

is($mime->mime_type_for('foo'), 'text/foo', 'mime type foo is found');

ok($mime->add_mime_type(bar => 'foo'), 'define bar as alias to foo');
is($mime->mime_type_for('bar'), 'text/foo', 'mime type bar is found');

# test alias on Dancer.pm

is(mime_type_for('foo.zip'), 'application/zip',
    "a mime_type is found with MIME::Types");

is(mime_type_for('foo.nonexistent'), Dancer::MIME::default_mime_type(),
    'mime_type defaults' );

config->{default_mime_type} = "text/plain";

is(mime_type_for('foo.nonexistent'), "text/plain", 'mime_type defaults' );
