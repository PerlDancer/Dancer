package Dancer::Hook;
# ABSTRACT: Class to manipulate hooks with Dancer

=head1 SYNOPSIS

  # inside a plugin
  use Dancer::Hook;
  Dancer::Hook->register_hooks_name(qw/before_auth after_auth/);

=cut

use strict;
use warnings;
use Carp;

use base 'Dancer::Object';

__PACKAGE__->attributes(qw/name code properties/);

use Dancer::Factory::Hook;
use Dancer::Hook::Properties;

=method new ($name => $code)

Creates a new hook object given a name and a code clock.  An optional
hashref can be passed after the name (and before the code) with hook
properties.

=cut

sub new {
    my ($class, @args) = @_;

    my $self = bless {}, $class;

    if (!scalar @args) {
        croak "one name and a coderef are required";
    }

    my $hook_name = shift @args;

    # XXX at the moment, we have a filer position named "before_template".
    # this one is renamed "before_template_render", so we need to alias it.
    # maybe we need to deprecate 'before_template' to enforce the use
    # of 'hook before_template_render => sub {}' ?
    $hook_name = 'before_template_render' if $hook_name eq 'before_template';

    $self->name($hook_name);

    my ( $properties, $code );
    if ( scalar @args == 1 ) {
        $properties = Dancer::Hook::Properties->new();
        $code       = shift @args;
    }
    elsif ( scalar @args == 2 ) {
        my $prop = shift @args;
        $properties = Dancer::Hook::Properties->new(%$prop);
        $code       = shift @args;
    }
    else {
        croak "something's wrong";
    }

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

    $self->properties($properties);
    $self->code($compiled_filter);

    Dancer::Factory::Hook->instance->register_hook($self);
    return $self;
}

1;

# FIXME: where are these coming from?
=pod

=method register_hook ($hook_name, [$properties], $code)

    hook 'before', {apps => ['main']}, sub {...};

    hook 'before' => sub {...};

Attaches a hook at some point, with a possible list of properties.

Currently supported properties:

=over 4

=item apps

    an array reference containing apps name

=back

=method register_hooks_name

Add a new hook name, so developpers of application can insert some
code at this point.

    package My::Dancer::Plugin;
    Dancer::Hook->instance->register_hooks_name(qw/before_auth after_auth/);

=method hook_is_registered

Test if a hook with this name has already been registered.

=method execute_hooks

Execute a list of hooks for some position

=method get_hooks_for

Returns the list of coderef registered for a given position

=cut

