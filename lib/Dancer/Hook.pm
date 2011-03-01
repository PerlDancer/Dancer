package Dancer::Hook;

use strict;
use warnings;
use Carp;

my $_registered_hooks_by_class = {};
my $_registered_hooks          = [];

sub register_hooks {
    my ( $class, @hooks_name ) = @_;

    my ($for) = caller();

    if ( !scalar @hooks_name ) {
        croak "a name for your hook is required!";
    }

    foreach my $hook_name (@hooks_name) {
        if ( $class->hook_is_registered($hook_name) ) {
            croak "$hook_name is already regsitered, please use another name";
        }

        $class->_add_hook($hook_name, $for);
    }
}

sub _add_hook {
    my ($class, $hook_name, $for) = @_;;
    push @{$_registered_hooks_by_class->{$for}}, $hook_name;
    push @$_registered_hooks, $hook_name;
}

sub get_hooks_name_list {
    my ($class, $for) = @_;
    if (!$for) {
        $class->_get_all_hooks();
    }else{
        $class->_get_hooks_for($for);
    }
}

sub _get_all_hooks { return $_registered_hooks }
sub _get_hooks_for { return $_registered_hooks_by_class->{$_[1]} }

sub hook_is_registered {
    my ( $class, $hook_name ) = @_;
    return grep { $_ eq $hook_name } @$_registered_hooks;
}

sub execute_hooks {
    my ($class, $hook_name, @args) = @_;

    croak("Can't ask for hooks without a position") unless $hook_name;

    if (!$class->hook_is_registered($hook_name)){
        croak("The hook '$hook_name' doesn't exists");
    }

    foreach my $hook (@{$class->get_hooks_for($hook_name)}) {
        $hook->(@args);
        # XXX ok, what if we want to modify the value of one of the arguments,
        # and this argument is not a ref ? like the content in the template
        # inside a 'after_template_render' ?
    }
}

sub get_hooks_for {
    my ( $class, $hook_name ) = @_;

    croak("Can't ask for hooks without a position") unless $hook_name;

    my $hooks = Dancer::App->current->registry->hooks->{$hook_name};
    $hooks ? return $hooks : [];
}

1;
