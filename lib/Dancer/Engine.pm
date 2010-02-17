package Dancer::Engine;

# This is the mother class of every engine abstract class.
# This allow us to put in that single place the engine creation
# from a namespace and a name, to its configuration initialization.

use strict;
use warnings;
use Dancer::ModuleLoader;
use base 'Dancer::Object';

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
    
    die "cannot build engine without type and name " 
        unless $name and $type;

    my $class_name = ucfirst($type);
    my $namespace = "Dancer::${class_name}";

    $config ||= {};
    $config->{engines} ||= {};
    my $settings = $config->{engines}{$name} || {};

    # trying to load the engine
    my $engine_class =
      Dancer::ModuleLoader->class_from_setting($namespace => $name);

    die "unknown $type engine '$name'"
      unless Dancer::ModuleLoader->require($engine_class);

    # creating the engine
    return $engine_class->new(
        name     => $name,
        type     => $type,
        config   => $settings,
    );
}

1;
__END__
