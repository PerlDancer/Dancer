package Dancer::Factory::Hook;
# ABSTRACT: takes track of registered hooks

use strict;
use warnings;
use Carp;

use base 'Dancer::Object::Singleton';

__PACKAGE__->attributes(qw/hooks registered_hooks/);

sub init {
    my ( $class, $self ) = @_;
    $self->hooks( {} );
    $self->registered_hooks( [] );
    return $self;
}


=method install_hooks

Receives a list of hooks to be installed in current object.

=cut
sub install_hooks {
    my ( $self, @hooks_name ) = @_;

    if ( !scalar @hooks_name ) {
        croak "at least one name is required";
    }

    foreach my $hook_name (@hooks_name) {
        if ( $self->hook_is_registered($hook_name) ) {
            croak "$hook_name is already regsitered, please use another name";
        }
        $self->_add_hook( $hook_name );
    }
}

=method register_hook

given a C<Dancer::Hook> object, this method registers it.

=cut
sub register_hook {
    my ( $self, $hook ) = @_;
    $self->_add_registered_hook( $hook->name, $hook->code );
}

=method hook_is_registered

Given an hook name, return a true value if it is currently registered.

=cut
sub hook_is_registered {
    my ( $self, $hook_name ) = @_;
    return grep { $_ eq $hook_name } @{$self->registered_hooks};
}

=method execute_hooks

Call with a hook name and optional hook arguments. Will execute
registered hooks.

=cut
sub execute_hooks {
    my ($self, $hook_name, @args) = @_;

    croak("Can't ask for hooks without a position") unless $hook_name;

    if (!$self->hook_is_registered($hook_name)){
        croak("The hook '$hook_name' doesn't exists");
    }

   foreach my $h (@{$self->get_hooks_for($hook_name)}) {
       $h->(@args);
   }
}

=method get_hooks_for

Given an hook name, return the L<Dancer::Hook> object.

=cut
sub get_hooks_for {
    my ( $self, $hook_name ) = @_;

    croak("Can't ask for hooks without a position") unless $hook_name;

    $self->hooks->{$hook_name} || [];
}

# private

sub _add_registered_hook {
    my ($class, $hook_name, $compiled_filter) = @_;
    push @{$class->hooks->{$hook_name}}, $compiled_filter;
}

sub _add_hook {
    my ($self, $hook_name ) = @_;
    push @{$self->registered_hooks}, $hook_name;
}


1;
