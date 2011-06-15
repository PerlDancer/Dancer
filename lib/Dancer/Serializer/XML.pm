package Dancer::Serializer::XML;
# ABSTRACT: XML serializer engine

use strict;
use warnings;
use Carp;
use Dancer::ModuleLoader;
use base 'Dancer::Serializer::Abstract';

# singleton for the XML::Simple object
my $_xs;

sub init {
    my ($self) = @_;
    die 'XML::Simple is needed and is not installed'
      unless $self->_loaded_xmlsimple;
    die 'XML::Simple needs XML::Parser or XML::SAX and neither is installed'
      unless $self->_loaded_xmlbackends;
    $_xs = XML::Simple->new();
}

=func from_xml

Helpder subroutine that deserializes from XML.

=cut
sub from_xml {
    my $s = Dancer::Serializer::XML->new;
    $s->deserialize(@_);
}

=func to_xml

Helpder subroutine that serializes to XML.

=cut
sub to_xml {
    my $s = Dancer::Serializer::XML->new;
    $s->serialize(@_);
}

=method serialize

Serialize a data structure to a XML structure.

=cut
sub serialize {
    my $self    = shift;
    my $entity  = shift;
    my %options = (RootName => 'data', @_);
    $_xs->XMLout($entity, %options);
}

=method deserialize

Deserialize a XML structure to a data structure

=cut
sub deserialize {
    my $self = shift;
    $_xs->XMLin(@_);
}

=method content_type

Return 'text/xml'

=cut
sub content_type {'text/xml'}


# privates

sub _loaded_xmlsimple {
    Dancer::ModuleLoader->load('XML::Simple');
}

sub _loaded_xmlbackends {
    # we need either XML::Parser or XML::SAX too
    Dancer::ModuleLoader->load('XML::Parser') or
    Dancer::ModuleLoader->load('XML::SAX');
}



1;
__END__


