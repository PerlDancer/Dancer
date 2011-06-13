package Dancer::Template;
# ABSTRACT: template wrapper

=head1 DESCRIPTION

This module is the wrapper that provides support for different 
template engines.

=cut

use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer::Engine;

# singleton for the current template engine
my $_engine;

=method engine

Accessor to the singleton containing the active engine.

    my $e = Dancer::Template->engine;

=cut

sub engine { $_engine }

=method init

Init the engine according to the settings the template engine module will
take from the setting name. The initialized engine will be accessible via the
C<engine> accessor.

    Dancer::Template->init('template_toolkit', $options);

=cut

sub init {
    my ($class, $name, $config) = @_;
    $name ||= 'simple';
    $_engine = Dancer::Engine->build(template => $name, $config);
}

1;
__END__

=head1 USAGE

=head2 Default engine

The default engine used by Dancer::Template is Dancer::Template::Simple.
If you want to change the engine used, you have to edit the B<template>
configuration variable.

=head2 Configuration

The B<template> configuration variable tells Dancer which engine to use
for rendering views.

You change it either in your config.yml file:

    # setting TT as the template engine
    template: "template_toolkit" 

Or in the application code:

    # setting TT as the template engine
    set template => 'template_toolkit';

=cut
