package Dancer::Serializer::CBOR;

use strict;
use warnings;
use Carp;
use Dancer::ModuleLoader;
use Dancer::Exception qw(:all);
use base 'Dancer::Serializer::Abstract';

# helpers

sub from_cbor {
    my ($cbor) = @_;
    my $s = Dancer::Serializer::CBOR->new;
    $s->deserialize($cbor);
}

sub to_cbor {
    my ($data) = @_;
    my $s = Dancer::Serializer::CBOR->new;
    $s->serialize($data);
}

# class definition

sub loaded { Dancer::ModuleLoader->load('CBOR::XS') }

sub init {
    my ($self) = @_;
    raise core_serializer => 'CBOR::XS is needed and is not installed'
      unless $self->loaded;
}

sub serialize {
    my ($self, $entity) = @_;
    CBOR::XS::encode_cbor($entity);
}

sub deserialize {
    my ($self, $content) = @_;
    CBOR::XS::decode_cbor($content);
}

sub content_type {'application/cbor'}

1;
__END__

=head1 NAME

Dancer::Serializer::CBOR - serializer for handling CBOR data

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 serialize

Serialize a data structure to a concise binary object representation.

=head2 deserialize

Deserialize a concise binary object representation to a data structure.

=head2 content_type

Return 'application/cbor'

=head1 SEE ALSO

L<CBOR::XS>

=head1 AUTHOR

David Zurborg, C<< <zurborg at cpan.org> >>
