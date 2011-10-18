package Dancer::Factory::Hook;

use strict;
use warnings;
use Carp;

use base 'Dancer::Object::Singleton';
use Dancer::Exception qw(:all);

__PACKAGE__->attributes(qw/ hooks registered_hooks/);

sub init {
    my ( $class, $self ) = @_;
    $self->hooks( {} );
    $self->registered_hooks( [] );
    return $self;
}

sub install_hooks {
    my ( $self, @hooks_name ) = @_;

    if ( !scalar @hooks_name ) {
        raise core_factory_hook => "at least one name is required";
    }

    foreach my $hook_name (@hooks_name) {
        if ( $self->hook_is_registered($hook_name) ) {
            raise core_factory_hook => "$hook_name is already regsitered, please use another name";
        }
        $self->_add_hook( $hook_name );
    }
}

sub register_hook {
    my ( $self, $hook ) = @_;
    $self->_add_registered_hook( $hook->name, $hook->code );
}

sub _add_registered_hook {
    my ($class, $hook_name, $compiled_filter) = @_;
    push @{$class->hooks->{$hook_name}}, $compiled_filter;
}

sub _add_hook {
    my ($self, $hook_name ) = @_;
    push @{$self->registered_hooks}, $hook_name;
}

sub hook_is_registered {
    my ( $self, $hook_name ) = @_;
    return grep { $_ eq $hook_name } @{$self->registered_hooks};
}

sub execute_hooks {
    my ($self, $hook_name, @args) = @_;

    raise core_factory_hook => "Can't ask for hooks without a position" unless $hook_name;

    if (!$self->hook_is_registered($hook_name)){
        raise core_factory_hook => "The hook '$hook_name' doesn't exists";
    }

   foreach my $h (@{$self->get_hooks_for($hook_name)}) {
       $h->(@args);
   }
}

sub get_hooks_for {
    my ( $self, $hook_name ) = @_;

    raise core_factory_hook => "Can't ask for hooks without a position" unless $hook_name;

    $self->hooks->{$hook_name} || [];
}


1;
