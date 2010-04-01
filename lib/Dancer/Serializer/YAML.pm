package Dancer::Serializer::YAML;

use strict;
use warnings;
use Dancer::ModuleLoader;
use base 'Dancer::Serializer::Abstract';

sub init {
    die 'YAML is needed and is not installed'
      unless Dancer::ModuleLoader->load('YAML');
}

sub serialize {
    my ($self, $entity) = @_;
    YAML::Dump $entity;
}

sub deserialize {
    my ($self, $content) = @_;
    YAML::Load $content;
}

sub content_type { 'text/x-yaml' }

1;
