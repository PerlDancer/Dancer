package Dancer::Hook;

use strict;
use warnings;
use Carp;
use base 'Dancer::Object::Singleton';

use Dancer::Hook::Properties;

Dancer::Hook->attributes(qw/ hooks registered_hooks registered_hooks_by_class/);

sub init {
    my ( $class, $self ) = @_;
    $self->hooks( {} );
    $self->registered_hooks([]);
    return $self;
}

sub register_hook {
    my ($class, $hook_name) = (shift, shift);

    my ( $properties, $code );

    if ( scalar @_ == 1 ) {
        $properties = Dancer::Hook::Properties->new();
        $code       = shift;
    }
    elsif ( scalar @_ == 2 ) {
        my $prop = shift;
        $properties = Dancer::Hook::Properties->new(%$prop);
        $code       = shift;
    }
    else {
        croak "something's wrong";
    }

    $class->_register_hook( $hook_name, $properties, $code );
}

sub _register_hook {
    my ($class, $hook_name, $properties, $code) = @_;

    my $compiled_filter = sub {
        return if Dancer::SharedData->response->halted;

        my $app = Dancer::App->current();
        return unless $properties->should_run_this_app($app->name);

        Dancer::Logger::core( "entering " . $hook_name . " hook" );
        eval { $code->(@_) };
        if ($@) {
            my $err = Dancer::Error->new(
                code    => 500,
                title   => $hook_name . ' filter error',
                message => "An error occured while executing the filter named $hook_name: $@"
            );
            return Dancer::halt( $err->render );
        }
    };

    # XXX at the moment, we have a filer position named "before_template".
    # this one is renamed "before_template_render", so we need to alias it.
    # maybe we need to deprecate 'before_template' to enforce the use
    # of 'hook before_template_render => sub {}' ?
    $hook_name = 'before_template_render' if $hook_name eq 'before_template';

    $class->_add_registered_hook($hook_name, $compiled_filter);
}

sub _add_registered_hook {
    my ($class, $hook_name, $compiled_filter) = @_;
    push @{$class->hooks->{$hook_name}}, $compiled_filter;
}

sub register_hooks_name {
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

    croak("Can't ask for hooks without a position") unless $hook_name;

    if (!$self->hook_is_registered($hook_name)){
        croak("The hook '$hook_name' doesn't exists");
    }

    $_->(@args) foreach @{$self->get_hooks_for($hook_name)};
}

sub get_hooks_for {
    my ( $self, $hook_name ) = @_;

    croak("Can't ask for hooks without a position") unless $hook_name;

    $self->hooks->{$hook_name} || [];
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

=head2 register_hook ($hook_name, [$properties], $code)

    hook 'before', {apps => ['main']}, sub {...};

    hook 'before' => sub {...};
    
Attaches a hook at some point, with a possible list of properties.

Currently supported properties:

=over 4

=item apps

    an array reference containing apps name

=back

=head2 register_hooks_name

Add a new hook name, so developpers of application can insert some code at this point.

    package My::Dancer::Plugin;
    Dancer::Hook->instance->register_hooks_name(qw/before_auth after_auth/);

=head2 hook_is_registered

Test if a hook with this name has already been registered.

=head2 execute_hooks

Execute a list of hooks for some position    

=head2 get_hooks_for

Returns the list of coderef registered for a given position

=head1 AUTHORS

This module has been written by Alexis Sukrieh and others.

=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.
