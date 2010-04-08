package Dancer::Serializer::XML;

use strict;
use warnings;
use Dancer::ModuleLoader;
use base 'Dancer::Serializer::Abstract';

my $xml_serializer;

my $_loaded;
sub init {
    die 'XML::Simple is needed and is not installed'
      unless Dancer::ModuleLoader->load('XML::Simple');

    $xml_serializer = XML::Simple->new( ForceArray => 0 );
    $_loaded = 1;
}

sub serialize {
    my ( $self, $entity ) = @_;
    if ($_loaded) {
        $xml_serializer->XMLout( { data => $entity } );
    }else{
        # die ?
    }
}

sub deserialize {
    my ( $self, $content ) = @_;
    if ($_loaded) {
        $xml_serializer->XMLin($content);
    }else{
        # die ?
    }
}

sub content_type { 'text/xml' }

1;
