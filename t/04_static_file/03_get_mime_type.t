use strict;
use warnings;
use Test::More tests => 2;

use Dancer::ModuleLoader;
use Dancer::Renderer;

use lib 't/lib';
use EasyMocker;

is(Dancer::Renderer::get_mime_type('foo.zip'), 'application/zip',
    "a mime_type is found with MIME::Types");

is(Dancer::Renderer::get_mime_type('foo.nonexistent'), 'text/plain',
    'mime_type defaults to text/plain' );
