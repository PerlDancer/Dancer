package Dancer::Template;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: template wrapper for Dancer
$Dancer::Template::VERSION = '1.3202';
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

=encoding UTF-8

=head1 NAME

Dancer::Template - template wrapper for Dancer

=head1 VERSION

version 1.3202

=head1 DESCRIPTION

This module is the wrapper that provides support for different 
template engines.

=head1 USAGE

=head2 Default engine

The default engine used by Dancer::Template is L<< Dancer::Template::Simple >>.
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

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
