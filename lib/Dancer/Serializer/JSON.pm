package Dancer::Serializer::JSON;

use strict;
use warnings;
use Dancer::ModuleLoader;
use base 'Dancer::Serializer::Abstract';

sub init {
    die 'JSON is needed and is not installed'
      unless Dancer::ModuleLoader->load('JSON');
}

sub serialize {
    my ($self, $entity) = @_;
    JSON::encode_json($entity);
}

sub deserialize {
    my ($self, $content) = @_;
    JSON::decode_json($content);
}

sub content_type { 'application/json' }

1;
__END__

=head1 NAME

Dancer::Serializer::JSON

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item B<serialize>

Serialize a data structure to a JSON structure.

=item B<deserialize>

Deserialize a JSON structure to a data structure

=item B<content_type>

Return 'application/json'

=back
