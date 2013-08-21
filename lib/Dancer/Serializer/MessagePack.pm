package Dancer::Serializer::MessagePack;

use strict;
use warnings;
use Carp;
use Dancer::ModuleLoader;
use Dancer::Deprecation;
use Dancer::Config 'setting';
use Dancer::Exception qw(:all);
use base 'Dancer::Serializer::Abstract';


# helpers

sub from_msgpack {
  my $s = Dancer::Serializer::MessagePack->new;
  $s->deserialize(@_);
}

sub to_msgpack {
  my $s = Dancer::Serializer::MessagePack->new;
  $s->serialize(@_);
}

# class definition

sub loaded { Dancer::ModuleLoader->load_with_params('Data::MessagePack') }

sub init {
  my ($self) = @_;
  raise core_serializer => 'Data::MessagePack is needed and is not installed'
    unless $self->loaded;
}

sub serialize {
  my $self   = shift;
  my $entity = shift;

  if (ref($entity) eq "HASH") {
    return Data::MessagePack::pack(%$entity, 4096) ||
      croak "Unable to serialize the entity! \n";
  } elsif (ref($entity) eq "ARRAY") {
    return Data::MessagePack::pack(@$entity, 4096) ||
      croak "Unable to serialize the entity! \n";
  }
}

sub deserialize {
  my $self   = shift;
  my $entity = shift;

  my $unpacker = Data::MessagePack::Unpacker->new;
  my $limit = length $entity;
  my $off = 0;
  my $unpacked_entity = ();
  while (1) {
    $off = $unpacker->execute($entity, $off);
    $unpacked_entity .= $unpacker->data;

    $unpacker->reset;
    last if $off >= $limit;
  }
  return $unpacked_entity || "Unable to deserialize the entity\n";
}

sub content_type {'application/x-msgpack'}

1;

