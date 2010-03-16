package Dancer::Serializer::YAML;

use strict;
use warnings;
use YAML;
use base 'Dancer::Serializer::Abstract';

sub serialize {
    my ($self, $entity) = @_;
    Dump $entity;
}

sub deserialize {
    my ($self, $content) = @_;
    Load $content;
}

sub content_type {
    "text/x-yaml";
}

1;
