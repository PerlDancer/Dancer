package Dancer::Serializer::XML;

use strict;
use warnings;
use XML::Simple;
use base 'Dancer::Serializer::Abstract';

my $xml_serializer = XML::Simple->new( ForceArray => 0, );

sub serialize {
    my ( $self, $entity ) = @_;
    $xml_serializer->XMLout( { data => $entity } );
}

sub deserialize {
    my ( $self, $content ) = @_;
    $xml_serializer->XMLin($content);
}

sub content_type {
    "text/xml";
}

1;
