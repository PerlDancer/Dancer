package Dancer::Template;

use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer::Engine;

# singleton for the current template engine
my $_engine;
sub engine { $_engine }

# init the engine according to the settings the template engine module will
# take from the setting name.
sub init {
    my ($class, $name, $config) = @_;
    $name ||= 'simple';
    $_engine = Dancer::Engine->build(template => $name, $config);
}

1;
__END__

=pod

=head1 NAME

Dancer::Template - template wrapper for Dancer

=head1 DESCRIPTION

This module is the wrapper that provides support for different 
template engines.

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

=head1 AUTHORS

This module has been written by Alexis Sukrieh. See the AUTHORS file that comes
with this distribution for details.

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=head1 SEE ALSO

See L<Dancer> for details about the complete framework.

You can also search the CPAN for existing engines in the Dancer::Template
namespace.

=cut
