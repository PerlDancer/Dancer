use strict;
use warnings;
use Test::More tests => 3;

use Dancer::ModuleLoader;
use Dancer::Renderer;

use lib 't/lib';
use EasyMocker;

my $mocker = { 'File::MimeInfo::Simple' => 0 };
mock 'Dancer::ModuleLoader'
    => method 'load'
    => should sub { $mocker->{$_[1]} };

is(Dancer::ModuleLoader->load('File::MimeInfo::Simple'), 0, 
    'mocker is set');

is(Dancer::Renderer::get_mime_type('foo.arj'), 'application/x-arj',
    "a mime_type is found without File::MimeInfo::Simple");

eval { Dancer::Renderer::get_mime_type('foo.nonexistent') };
like $@, qr/unknown mime_type for 'foo.nonexistent'/,
    "unknown mime_type exception caught";

