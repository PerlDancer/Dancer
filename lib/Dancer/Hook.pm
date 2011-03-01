package Dancer::Hook;

use strict;
use warnings;
use Carp;

my $_registered_hooks_by_class = {};
my $_registered_hooks          = [];
my $_apps                      = {};

sub register_hook {
    my ( $class, $hook_name, $code ) = @_;
    my $app = Dancer::App->current->name;
    $class->_register_hook($app, $hook_name, $code);
}

sub _register_hook {
    my ($class, $app, $name, $code) = @_;

    my $compiled_filter = sub {
        return if Dancer::SharedData->response->halted;
        Dancer::Logger::core("entering " . $name . " hook");
        eval { $code->(@_) };
        if ($@) {
            my $err = Dancer::Error->new(
                code  => 500,
                title => $name . ' filter error',
                message =>
                  "An error occured while executing the filter named $name: $@"
            );
            return Dancer::halt($err->render);
        }
    };

    # XXX at the moment, we have a filer position named "before_template".
    # this one is renamed "before_template_render", so we need to alias it.
    # maybe we need to deprecate 'before_template' to enforce the use
    # of 'hook before_template_render => sub {}' ?
    $name = 'before_template_render' if $name eq 'before_template';
    push @{$_apps->{$app}->{$name}}, $compiled_filter;
    return $compiled_filter;
}

sub register_hooks_name {
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

sub get_hooks_for_app {
    my ($class, $app_name) = @_;
    return $_apps->{$app_name};
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
    my ( $class, $hook_name, $app_name ) = @_;

    croak("Can't ask for hooks without a position") unless $hook_name;

    my $hooks = [];
    if ($app_name) {
        push @$hooks, @{$class->_get_hooks_for_app($hook_name, $app_name)};
    }else{
        foreach my $app ( keys %$_apps ) {
            push @$hooks, @{$class->_get_hooks_for_app($hook_name, $app)};
        }
    }
    $hooks;
}

sub _get_hooks_for_app {
    my ( $class, $hook_name, $app ) = @_;
    my $hooks = [];
    if ( defined $_apps->{$app}->{$hook_name} ) {
        push @$hooks, @{ $_apps->{$app}->{$hook_name} };
    }
    $hooks;
}

1;

=head1 NAME

Dancer::Hook - Class to manipulate hooks with Dancer

=head1 DESCRIPTION

Manipulate hooks with Dancer

=head1 SYNOPSIS

  # inside a plugin
  use Dancer::Hook;
  Dancer::Hook->register_hooks_name(qw/before_auth after_auth/);

=head1 METHODS

=head2 register_hook

=head2 register_hooks_name

=head2 get_hooks_name_list

=head2 hook_is_registered

=head2 execute_hooks

=head2 get_hooks_for

=head1 AUTHORS

This module has been written by Alexis Sukrieh and others.

=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.
