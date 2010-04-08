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
    YAML::Dump($entity);
}

sub deserialize {
    my ($self, $content) = @_;
    YAML::Load($content);
}

sub content_type { 'text/x-yaml' }

1;
__END__

=head1 NAME

Dancer::Serializer::YAML

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item B<serialize>

Serialize a data structure to a YAML structure.

=item B<deserialize>

Deserialize a YAML structure to a data structure

=item B<content_type>

Return 'application/json'

=back
