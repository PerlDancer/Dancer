use strict;
use warnings;

use Test::More;
use Dancer::ModuleLoader;
use Dancer::Renderer;
use Dancer::FileUtils 'path';

plan skip_all => "File::MimeInfo::Simple needed" 
    unless Dancer::ModuleLoader->load('File::MimeInfo::Simple');

plan tests => 4;

is(Dancer::Renderer::get_mime_type('foo.arj'), 'application/x-arj',
    "a mime_type is found without File::MimeInfo::Simple");

eval { Dancer::Renderer::get_mime_type('foo.nonexistent') };
like $@, qr/Unable to read file: foo.nonexistent/,
    "unknown mime_type exception caught, should read a file";

my $test_file = path('t', '04_static_file', 'foo.nonexistent');
open TESTFILE, '>', $test_file;
print TESTFILE "this is plain text\n";
close TESTFILE;

my $mt;
eval { $mt = Dancer::Renderer::get_mime_type($test_file) };
is $@, '', "unknown mime_type is detected with File::MimeInfo::Simple";
like $mt, qr/text\/plain/, "mime_type is text/plain";

unlink $test_file;

