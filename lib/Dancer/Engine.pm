package Dancer::Engine;

# This is the base-class of every engine abstract class.
# This allow us to put in that single place the engine creation
# from a namespace and a name, to its configuration initialization.

use strict;
use warnings;
use Carp;
use Dancer::ModuleLoader;
use base 'Dancer::Object';
use Dancer::Exception qw(:all);

# constructor arguments:
#      name     => $name_of_the_engine
#      settings => $hash_of_engine_settings
Dancer::Engine->attributes(qw(name type));

# Accessor to the config hash, it may not be initialized if someone
# creates a new engine without giving the appropriate arguments.
# e.g. Dancer::Template::Simple->new();
sub config {
    my ($self) = @_;
    return $self->{config} if defined $self->{config};
    $self->{config} = {};
}

# static method for initializing an engine
# this will create an engine instance of the appropriate $type, named $name
# if Dancer::$type::$name exists.
sub build {
    my ($class, $type, $name, $config) = @_;

    raise core_engine => "cannot build engine without type and name "
      unless $name and $type;

    my $class_name = $class->_engine_class($type);

    $config ||= {};
    $config->{engines} ||= {};
    my $settings = $config->{engines}{$name} || {};

    # trying to load the engine
    my $engine_class =
      Dancer::ModuleLoader->class_from_setting($class_name => $name);

    raise core_engine => "unknown $type engine '$name', "
      . "perhaps you need to install $engine_class?"
      unless Dancer::ModuleLoader->load($engine_class);

    # creating the engine
    return $engine_class->new(
        name   => $name,
        type   => $type,
        config => $settings,
    );
}

sub _engine_class {
    my ($class, $type) = @_;
    $type = ucfirst($type);
    return "Dancer::${type}";
}

sub engine {
    my ($class, $type) = @_;
    return $class->_engine_class($type)->engine();
}


1;

__END__

=pod

=head1 NAME

Dancer::Engine - base class for Dancer engines

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

=head1 ATTRIBUTES

=head2 name

The name of the engine, such as I<JSON>, or I<Simple>.

=head2 type

The type of the engine, such as I<Serializer>, or I<Session>.

=head1 METHODS/SUBROUTINES

=head2 config

Fetches the configuration of the engine.

    my $configuration = $engine->config;

You can B<only> set the configuration at initialization time, not after.

=head2 build

Builds and returns the engine.

    my $engine = Dancer::Engine->build( $type => $name, $config );

=head1 AUTHOR

Alexis Sukrieh

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2010 Alexis Sukrieh.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

