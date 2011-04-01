use strict;
use warnings;
use Test::More import => ['!pass'], tests => 2;

use Dancer;

use t::lib::EasyMocker;

is(mime->for_file('foo.zip'), 'application/zip',
    "a mime_type is found with MIME::Types");

is(mime->for_file('foo.nonexistent'), mime->default,
    'mime_type defaults to the default defined mime_type' );
