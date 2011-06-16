package Dancer::Engine;
# ABSTRACT: base class for Dancer engines

=head1 SYNOPSIS

   my $engine = Dancer::Engine->build( Serializer => 'JSON', $configuration );

=head1 DESCRIPTION

Dancer has various engines such Serializer engines, Template engines, Logger
engines and Session handlers engines. This is the base class for all Dancer
engines.

If you're writing an engine of a common type (such as those mentioned above),
you probably want to simply use their base class, which in turn use
L<Dancer::Engine>. For example, Template engines inherit from
L<Dancer::Template::Abstract> and Serializer engines inherit from
L<Dancer::Serializer::Abstract>. Those I<Abstract> base classes inherit from
L<Dancer::Engine>.

If a new type of Dancer engine is created, it is best it inherits from this
class.

=cut


=attr name

The name of the engine, such as I<JSON>, or I<Simple>.

=attr type

The type of the engine, such as I<Serializer>, or I<Session>.

=cut

use strict;
use warnings;
use Carp;
use Dancer::ModuleLoader;
use base 'Dancer::Object';

# constructor arguments:
#      name     => $name_of_the_engine
#      settings => $hash_of_engine_settings
Dancer::Engine->attributes(qw(name type));

=method config

Fetches the configuration of the engine.

    my $configuration = $engine->config;

You can B<only> set the configuration at initialization time, not after.

=cut
sub config {
    my ($self) = @_;
    return $self->{config} if defined $self->{config};
    $self->{config} = {};
}


=method build

Builds and returns the engine.

    my $engine = Dancer::Engine->build( $type => $name, $config );

=cut
sub build {
    my ($class, $type, $name, $config) = @_;

    croak "cannot build engine without type and name "
      unless $name and $type;

    my $class_name = $class->_engine_class($type);

    $config ||= {};
    $config->{engines} ||= {};
    my $settings = $config->{engines}{$name} || {};

    # trying to load the engine
    my $engine_class =
      Dancer::ModuleLoader->class_from_setting($class_name => $name);

    croak "unknown $type engine '$name', "
      . "perhaps you need to install $engine_class?"
      unless Dancer::ModuleLoader->load($engine_class);

    # creating the engine
    return $engine_class->new(
        name   => $name,
        type   => $type,
        config => $settings,
    );
}

=method engine

Acessor to an engine, based on engine type.

=cut

sub engine {
    my ($class, $type) = @_;
    return $class->_engine_class($type)->engine();
}

# Privates

sub _engine_class {
    my ($class, $type) = @_;
    $type = ucfirst($type);
    return "Dancer::${type}";
}

1;

