package Dancer::Serializer::XML;

use strict;
use warnings;
use Dancer::ModuleLoader;
use base 'Dancer::Serializer::Abstract';

my $xml_serializer;

sub init {
    die 'XML::Simple is needed and is not installed'
      unless Dancer::ModuleLoader->load('XML::Simple');

    $xml_serializer = XML::Simple->new( ForceArray => 0 );
}

sub serialize {
    my ( $self, $entity ) = @_;
    $xml_serializer->XMLout( { data => $entity } );
}

sub deserialize {
    my ( $self, $content ) = @_;
    $xml_serializer->XMLin($content);
}

sub content_type { 'text/xml' }

1;
