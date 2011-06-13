package Dancer::Serializer::YAML;
# ABSTRACT: YAML serializer engine

use strict;
use warnings;
use Carp;
use Dancer::ModuleLoader;
use base 'Dancer::Serializer::Abstract';


sub init {
    my ($self) = @_;
    croak 'YAML is needed and is not installed'
      unless $self->loaded;
}


=method from_yaml

Helper subroutine, deserializes a YAML string.

=cut
sub from_yaml {
    my ($yaml) = @_;
    my $s = Dancer::Serializer::YAML->new;
    $s->deserialize($yaml);
}

=method to_yaml

Helper subroutine, serializes to a YAML string.

=cut
sub to_yaml {
    my ($data) = @_;
    my $s = Dancer::Serializer::YAML->new;
    $s->serialize($data);
}

=method loaded

Checks if the YAML serializer can be loaded.

=cut
sub loaded { Dancer::ModuleLoader->load('YAML') }

=method serialize

Serializes a data structure to a YAML structure.

=cut
sub serialize {
    my ($self, $entity) = @_;
    YAML::Dump($entity);
}

=method deserialize

Deserializes a YAML structure to a data structure

=cut
sub deserialize {
    my ($self, $content) = @_;
    YAML::Load($content);
}

=method content_type

Returns 'text/x-yaml'

=cut
sub content_type {'text/x-yaml'}

1;
__END__
