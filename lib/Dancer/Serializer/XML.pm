package Dancer::Serializer::XML;
#ABSTRACT: serializer for handling XML data

use strict;
use warnings;
use Carp;
use Dancer::ModuleLoader;
use Dancer::Config 'setting';
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
    # Disable fetching external entities, as that's a security hole: this allows
    # someone to fetch remote websites from the server, or to read local files.
    # This only works for XML::Parser when called directly from XML::Simple;
    # for XML::SAX we'll need to do some even *more* horrible stuff later on.
    $_xs = XML::Simple->new(
        ParserOpts => [
            Handlers => {
                ExternEnt => sub {
                    return '';
                }
            }
        ],
    );
}

sub serialize {
    my $self    = shift;
    my $entity  = shift;
    my %options = (RootName => 'data');

    my $s = setting('engines') || {};
    if (exists($s->{XMLSerializer}) && exists($s->{XMLSerializer}{serialize})) {
        %options = (%options, %{$s->{XMLSerializer}{serialize}});
    }

    %options = (%options, @_);


    $_xs->XMLout($entity, %options);
}

sub deserialize {
    my $self = shift;
    my $xml = shift;
    my %options = ();

    my $s = setting('engines') || {};
    if (exists($s->{XMLSerializer}) && exists($s->{XMLSerializer}{deserialize})) {
        %options = (%options, %{$s->{XMLSerializer}{deserialize}});
    }

    %options = (%options, @_);
    # This is the promised terrible hack: claim that the LWP-talking code has
    # already been loaded, and make sure that the handler that's called when
    # we're dealing with an external entity does nothing.
    # For whichever reason, this handler is called despite XML::Parser
    # (which on my machine is the only XML::SAX backend that can handle
    # external entities) having a ParseParamEnt option which is off by default,
    # but appears to only be used deep in the XML::Parser XS guts.
    no warnings 'redefine';
    local *XML::Parser::lwp_ext_ent_handler = sub { return };
    local $INC{'XML/Parser/LWPExternEnt.pl'} = 'Do not load this!';
    $_xs->XMLin($xml, %options);
    use warnings 'redefine';
}

sub content_type {'text/xml'}

1;
__END__

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 METHODS

=head2 serialize

Serialize a data structure to an XML structure.

=head2 deserialize

Deserialize an XML structure to a data structure

=head2 content_type

Return 'text/xml'

=head2 CONFIG FILE

You can set XML::Simple options for serialize and deserialize in the
config file:

   engines:
      XMLSerializer:
        serialize:
           AttrIndent: 1
        deserialize:
           ForceArray: 1
