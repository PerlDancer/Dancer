package Dancer::Serializer::JSON;

use strict;
use warnings;
use Carp;
use Dancer::ModuleLoader;
use Dancer::Deprecation;
use Dancer::Config 'setting';
use Dancer::Exception qw(:all);
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
    raise core_serializer => 'JSON is needed and is not installed'
      unless $self->loaded;
}

sub serialize {
    my $self   = shift;
    my $entity = shift;

    my $options = $self->_options_as_hashref(@_) || {};

    # Why doesn't $self->config have this?
    my $config = setting('engines') || {};
    $config = $config->{JSON} || {};

    # straight pass through of config options to JSON
    map { $options->{$_} = $config->{$_} } keys %$config;

    if (setting('environment') eq 'development' and not defined $options->{pretty}) {
        $options->{pretty} = 1;
    }

    JSON::to_json( $entity, $options );
}

sub deserialize {
    my $self   = shift;
    my $entity = shift;

    my $options = $self->_options_as_hashref(@_);
    JSON::from_json( $entity, $options );
}

sub _options_as_hashref {
    my $self = shift;

    return { utf8 => 1 } if scalar @_ == 0;

    if ( scalar @_ == 1 ) {
	my $options = shift;
	$options->{utf8} = 1 unless exists $options->{utf8};
        return $options;
    }
    elsif ( scalar @_ % 2 ) {
        carp "options for to_json/from_json must be key value pairs (as a hashref)";
    }
    else {
        Dancer::Deprecation->deprecated(
            version => '1.3002',
            fatal => 1,
            message => 'options as hash for to_json/from_json is DEPRECATED. please pass a hashref',
        );
    }
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

The L<JSON> module will pass configuration variables straight through.
Some of these can be useful when debugging/developing your app: B<pretty> and
B<canonical>, and others useful with ORMs like L<DBIx::Class>: B<allow_blessed>
and B<convert_blessed>.  Please consult the L<JSON> documentation for more
information and a full list of configuration settings. You can add extra
settings to the B<engines> configuration to turn these on. For example:

    engines:
        JSON:
            allow_blessed:   '1'
            canonical:       '1'
            convert_blessed: '1'


=head1 METHODS

=head2 serialize

Serialize a data structure to a JSON structure.

=head2 deserialize

Deserialize a JSON structure to a data structure

=head2 content_type

Return 'application/json'
