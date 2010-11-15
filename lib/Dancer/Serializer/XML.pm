package Dancer::Serializer::XML;

use strict;
use warnings;
use Carp;
use Dancer::ModuleLoader;
use base 'Dancer::Serializer::Abstract';

# singleton for the XML::Simple object
my $_xs;

# helpers

sub from_xml {
    my $s = Dancer::Serializer::XML->new;
    $s->deserialize(@_);
}

sub to_xml {
    my $s = Dancer::Serializer::XML->new;
    $s->serialize(@_);
}

# class definition

sub loaded_xmlsimple {
    Dancer::ModuleLoader->load('XML::Simple');
}

sub loaded_xmlbackends {
    # we need either XML::Parser or XML::SAX too
    Dancer::ModuleLoader->load('XML::Parser') or
    Dancer::ModuleLoader->load('XML::SAX');
}

sub init {
    my ($self) = @_;
    die 'XML::Simple is needed and is not installed'
      unless $self->loaded_xmlsimple;
    die 'XML::Simple needs XML::Parser or XML::SAX and neither is installed'
      unless $self->loaded_xmlbackends;
    $_xs = XML::Simple->new();
}

sub serialize {
    my $self = shift;
    $_xs->XMLout(@_);
}

sub deserialize {
    my $self = shift;
    $_xs->XMLin(@_);
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
