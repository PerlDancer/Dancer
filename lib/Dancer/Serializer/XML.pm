package Dancer::Serializer::XML;

use strict;
use warnings;
use Dancer::ModuleLoader;
use base 'Dancer::Serializer::Abstract';

# singleton for the XML::Simple object
my $_xs;

# helpers

sub from_xml {
    my ($xml) = @_;
    my $s = Dancer::Serializer::XML->new;
    $s->deserialize($xml);
}

sub to_xml {
    my ($data) = @_;
    my $s = Dancer::Serializer::XML->new;
    $s->serialize($data);
}

# class definition

sub loaded { Dancer::ModuleLoader->load('XML::Simple') }

sub init {
    my ($self) = @_;
    die 'XML::Simple is needed and is not installed'
      unless $self->loaded;
    $_xs = XML::Simple->new();
}

sub serialize {
    my ($self, $entity) = @_;
    $_xs->XMLout({data => $entity});
}

sub deserialize {
    my ($self, $content) = @_;
    $_xs->XMLin($content);
}

sub content_type {'text/xml'}

1;
__END__

=head1 NAME

Dancer::Serializer::XML - serializer for handling XML data

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item B<serialize>

Serialize a data structure to a XML structure.

=item B<deserialize>

Deserialize a XML structure to a data structure

=item B<content_type>

Return 'text/xml'

=back
