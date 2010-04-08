package Dancer::Serializer::YAML;

use strict;
use warnings;
use Dancer::ModuleLoader;
use base 'Dancer::Serializer::Abstract';

my $_loaded;
sub init {
    die 'YAML is needed and is not installed'
      unless Dancer::ModuleLoader->load('YAML');
    $_loaded = 1;
}

sub serialize {
    my ($self, $entity) = @_;
    if ($_loaded) {
        YAML::Dump($entity);
    }else{
        # die ?
    }
}

sub deserialize {
    my ($self, $content) = @_;
    if ($_loaded) {
        YAML::Load($content);
    }else{
        # die ?
    }
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
