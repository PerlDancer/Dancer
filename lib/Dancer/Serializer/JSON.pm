package Dancer::Serializer::JSON;
# ABSTRACT: JSON serializer engine
use strict;
use warnings;
use Carp;
use Dancer::ModuleLoader;
use Dancer::Deprecation;
use Dancer::Config 'setting';
use base 'Dancer::Serializer::Abstract';

sub init {
    my ($self) = @_;
    croak 'JSON is needed and is not installed'
      unless $self->loaded;
}



=func from_json

Helper subroutine deserialize a JSON string into a Perl data structure.

=cut
sub from_json {
    my $s = Dancer::Serializer::JSON->new;
    $s->deserialize(@_);
}

=func to_json

Helper subroutine serializes Perl data structures into a JSON string.

=cut
sub to_json {
    my $s = Dancer::Serializer::JSON->new;
    $s->serialize(@_);
}

=method loaded

Checks if JSON serializer can be loaded.

=cut
sub loaded { Dancer::ModuleLoader->load('JSON') }

=method serialize

Serialize a data structure to a JSON structure.

=cut
sub serialize {
    my $self   = shift;
    my $entity = shift;

    my $options = $self->_options_as_hashref(@_) || {};

    # Why doesn't $self->config have this?
    my $config = setting('engines') || {};
    $config = $config->{JSON} || {};

    if ( $config->{allow_blessed} && !defined $options->{allow_blessed} ) {
        $options->{allow_blessed} = $config->{allow_blessed};
    }
    if ( $config->{convert_blessed} ) {
        $options->{convert_blessed} = $config->{convert_blessed};
    }

    if (setting('environment') eq 'development' and not defined $options->{pretty}) {
        $options->{pretty} = 1;
    }

    JSON::to_json( $entity, $options );
}

=method deserialize

Deserialize a JSON structure to a data structure

=cut
sub deserialize {
    my $self   = shift;
    my $entity = shift;

    my $options = $self->_options_as_hashref(@_);
    JSON::from_json( $entity, $options );
}

=method content_type

Returns JSON content type string.

=cut
sub content_type {'application/json'}


# privates

sub _options_as_hashref {
    my $self = shift;

    return if scalar @_ == 0;

    if ( scalar @_ == 1 ) {
        return shift;
    }
    elsif ( scalar @_ % 2 ) {
        carp "options for to_json/from_json must be key value pairs (as a hashref)";
    }
    else {
        Dancer::Deprecation->deprecated(
            version => '1.3002',
            message => 'options as hash for to_json/from_json is DEPRECATED. please pass a hashref',
        );
        return { @_ };
    }
}


1;

__END__

=head1 DESCRIPTION

This class is an interface between Dancer's serializer engine
abstraction layer and the L<JSON> module.

In order to use this engine, use the template setting:

    serializer: JSON

This can be done in your config.yml file or directly in your app code
with the B<set> keyword. This serializer will also be used when the
serializer is set to B<mutable> and the correct Accept headers are
supplied.

The L<JSON> module has 2 configuration variables that can be useful
when working with ORM's like L<DBIx::Class>: B<allow_blessed> and
B<convert_blessed>.  Please consult the L<JSON> documentation for more
information. You can add extra settings to the B<engines>
configuration to turn these on.

    engines:
        JSON:
            allow_blessed: '1'
            convert_blessed: '1'

=cut

