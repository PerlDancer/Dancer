package Dancer::ModuleLoader;

# Abstraction layer for dynamic module loading

use strict;
use warnings;

sub load {
    my ($class, $module, $version) = @_;
    local $@;
    $version ? eval "use $module $version" : eval "use $module";
    return $@ ? 0 : 1;
}

sub require {
    my ($class, $module) = @_;
    local $@;
    eval "require $module";
    return $@ ? 0 : 1;
}

sub class_from_setting {
    my ($self, $namespace, $setting) = @_;

    my $class = '';
    for my $token (split /_/, $setting) {
        $class .= ucfirst($token);
    }
    return "${namespace}::${class}";
}

1;

__END__

=head1 NAME

Dancer::ModuleLoader - dynamic module loading helpers for Dancer core components

=head1 SYNOPSIS

Taken directly from Dancer::Template::TemplateToolkit (which is core):

    die "Template is needed by Dancer::Template::TemplateToolkit"
      unless Dancer::ModuleLoader->load('Template');

    # we now have Template loaded

=head1 DESCRIPTION

Sometimes in Dancer core we need to use modules, but we don't want to declare
them all in advance in compile-time. These could be because the specific modules
provide extra features which depend on code that isn't (and shouldn't) be in
core, or perhaps because we only want these components loaded in lazy style,
saving loading time a bit. For example, why load L<Template> (which isn't
required by L<Dancer>) when you don't use L<Dancer::Template::TemplateToolkit>?

To do such things takes a bit of code for localizing C<$@> and C<eval>ing. That
code has been refactored into this module to help Dancer core developers.

B<Please only use this for Dancer core modules>. If you're writing an external
Dancer module (L<Dancer::Template::Tiny>, L<Dancer::Session::Cookie>, etc.),
please simply "C<use ModuleYouNeed>" in your code and don't use this module.

=head1 METHODS/SUBROUTINES

=head2 load

Runs a "C<use ModuleYouNeed>".

    use Dancer::ModuleLoader;
    ...
    Dancer::ModuleLoader->load('Something')
        or die "Couldn't load Something\n";

Returns 1 if successful, 0 if not.

=head2 require

Runs a "C<require ModuleYouNeed>".

    use Dancer::ModuleLoader;
    ...
    Dancer::ModuleLoader->require('Something')
        or die "Couldn't require Something\n";

If you are unsure what you need (C<require> or C<load>), learn the differences
between C<require> and C<use>.

Returns 1 if successful, 0 if not.

=head2 class_from_setting

Given a setting in Dancer::Config, composes the class it should be.

This is the function that translates:

    # in config.yaml
    template: "template_toolkit"

To the class:

    Dancer::Template::TemplateToolkit

Example:

    use Dancer::ModuleLoader;
    my $class = Dancer::ModuleLoader->class_from_setting(
        'Dancer::Template' => 'template_toolkit',
    );

    # $class == 'Dancer::Template::TemplateToolkit

    $class = Dancer::ModuleLoader->class_from_setting(
        'Dancer::Template' => 'tiny',
    );

    # class == 'Dancer::Template::Tiny

=head1 AUTHOR

Alexis Sukrieh

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2010 Alexis Sukrieh.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

