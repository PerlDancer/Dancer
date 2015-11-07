package Dancer::Hook;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: Class to manipulate hooks with Dancer
$Dancer::Hook::VERSION = '1.3202';
use strict;
use warnings;
use Carp;

use base 'Dancer::Object';

__PACKAGE__->attributes(qw/name code properties/);

use Dancer::Factory::Hook;
use Dancer::Hook::Properties;
use Dancer::Exception qw(:all);

sub new {
    my ($class, @args) = @_;

    my $self = bless {}, $class;

    if (!scalar @args) {
        raise core_hook => "one name and a coderef are required";
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
        raise core_hook => "something's wrong with parameters passed to Hook constructor";
    }
    ref $code eq 'CODE'
      or raise core_hook => "the code argument passed to hook construction was not a CodeRef. Value was : '$code'";


    my $compiled_filter = sub {
        my @arguments = @_;
        return if Dancer::SharedData->response->halted;

        my $app = Dancer::App->current();
        return unless $properties->should_run_this_app($app->name);

        Dancer::Logger::core( "entering " . $hook_name . " hook" );

        $code->(@arguments);

    };

    $self->properties($properties);
    $self->code($compiled_filter);

    Dancer::Factory::Hook->instance->register_hook($self);
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Hook - Class to manipulate hooks with Dancer

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

  # inside a plugin
  use Dancer::Hook;
  Dancer::Hook->register_hooks_name(qw/before_auth after_auth/);

=head1 DESCRIPTION

Manipulate hooks with Dancer

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

Add a new hook name, so application developers can insert some code at this point.

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

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
