package Dancer::Serializer::YAML;

use strict;
use warnings;
use YAML::Syck;
use base 'Dancer::Serializer::Abstract';

sub serialize {
    my ($self, $entity) = @_;
    Dump $entity;
}

sub deserialize {
    my ($self, $content) = @_;
    Load $content;
}

1;
