package Dancer::Serializer::JSON;

use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer::Config 'setting';
use base 'Dancer::Serializer::Abstract';


# helpers

sub from_json {
    my $s = Dancer::Serializer::JSON->new;
    $s->deserialize(@_);
}

sub to_json {
    my $s = Dancer::Serializer::JSON->new;
    $s->serialize(@_);
}

# class definition

sub loaded { Dancer::ModuleLoader->load('JSON') }

sub init {
    my ($self) = @_;
    die 'JSON is needed and is not installed'
      unless $self->loaded;
}

sub serialize {
    my ($self, $entity, %options) = @_;

    # Why doesn't $self->config have this?
    my $config = setting('engines') || {};
    $config = $config->{JSON} || {};

    if ($config->{allow_blessed} && !defined $options{allow_blessed}) {
        $options{allow_blessed} = $config->{allow_blessed};
    }
    if ($config->{convert_blessed}) {
        $options{convert_blessed} = $config->{convert_blessed};
    }

    JSON::to_json($entity, \%options);
}

sub deserialize {
    my ($self, $entity, %options) = @_;
    JSON::from_json($entity, \%options);
}

sub content_type {'application/json'}

1;
__END__

=head1 NAME

Dancer::Serializer::JSON - serializer for handling JSON data

=head1 SYNOPSIS

=head1 DESCRIPTION

This class is an interface between Dancer's serializer engine abstraction layer
and the L<JSON> module.

In order to use this engine, use the template setting:

    serializer: JSON

This can be done in your config.yml file or directly in your app code with the
B<set> keyword. This serializer will also be used when the serializer is set
to B<mutable> and the correct Accept headers are supplied.

The L<JSON> module has 2 configuration variables that can be useful when working
with ORM's like L<DBIx::Class>: B<allow_blessed> and B<convert_blessed>.
Please consult the L<JSON> documentation for more information. You can add
extra settings to the B<engines> configuration to turn these on.

    engines:
        JSON:
            allow_blessed: '1'
            convert_blessed: '1'


=head2 METHODS

=over 4

=item B<serialize>

Serialize a data structure to a JSON structure.

=item B<deserialize>

Deserialize a JSON structure to a data structure

=item B<content_type>

Return 'application/json'

=back
