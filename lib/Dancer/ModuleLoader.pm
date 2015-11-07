package Dancer::ModuleLoader;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: dynamic module loading helpers for Dancer core components
$Dancer::ModuleLoader::VERSION = '1.3202';
# Abstraction layer for dynamic module loading

use strict;
use warnings;
use Module::Runtime qw/ use_module /;

sub load {
    my ($class, $module, $version) = @_;

    my ($res, $error) = $class->require($module, $version);
    return wantarray ? ($res, $error) : $res;
}

sub require {
    my ($class, $module, $version) = @_;
    eval { defined $version ? use_module( $module, $version ) 
                            : use_module( $module ) } 
        or return wantarray ? (0, $@) : 0;
    return 1; #success
}

sub load_with_params {
    my ($class, $module, @args) = @_;
    my ($res, $error) = $class->require($module);
    $res or return wantarray ? (0, $error) : 0;

    # From perlfunc : If no "import" method can be found then the call is
    # skipped, even if there is an AUTOLOAD method.
    if ($module->can('import')) {

        # bump Exporter Level to import symbols in the caller
        local $Exporter::ExportLevel = ($Exporter::ExportLevel || 0) + 1;
        local $@;
        eval { $module->import(@args) };
        my $error = $@;
        $error and return wantarray ? (0, $error) : 0;
    }
    return 1;
}

sub use_lib {
    my ($class, @args) = @_;
    use lib;
    local $@;
    lib->import(@args);
    my $error = $@;
    $error and return wantarray ? (0, $error) : 0;
    return 1;
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

=pod

=encoding UTF-8

=head1 NAME

Dancer::ModuleLoader - dynamic module loading helpers for Dancer core components

=head1 VERSION

version 1.3202

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

Runs something like "C<use ModuleYouNeed>" at runtime.

    use Dancer::ModuleLoader;
    ...
    Dancer::ModuleLoader->load('Something')
        or die "Couldn't load Something\n";

    # load version 5.0 or more
    Dancer::ModuleLoader->load('Something', '5.0')
        or die "Couldn't load Something\n";

    # load version 5.0 or more
    my ($res, $error) = Dancer::ModuleLoader->load('Something', '5.0');
    $res or die "Couldn't load Something : '$error'\n";

Takes in arguments the module name, and optionally the minimum version number required.

In scalar context, returns 1 if successful, 0 if not.
In list context, returns 1 if successful, C<(0, "error message")> if not.

If you need to give argument to the loading module, please use the method C<load_with_params>

=head2 require

Runs a "C<require ModuleYouNeed>".

    use Dancer::ModuleLoader;
    ...
    Dancer::ModuleLoader->require('Something')
        or die "Couldn't require Something\n";
    my ($res, $error) = Dancer::ModuleLoader->require('Something');
    $res or die "Couldn't require Something : '$error'\n";

If you are unsure what you need (C<require> or C<load>), learn the differences
between C<require> and C<use>.

Takes in arguments the module name.

In scalar context, returns 1 if successful, 0 if not.
In list context, returns 1 if successful, C<(0, "error message")> if not.

=head2 load_with_params

Runs a "C<use ModuleYouNeed qw(param1 param2 ...)>".

    use Dancer::ModuleLoader;
    ...
    Dancer::ModuleLoader->load_with_params('Something', qw(param1 param2) )
        or die "Couldn't load Something with param1 and param2\n";

    my ($res, $error) = Dancer::ModuleLoader->load_with_params('Something', @params);
    $res or die "Couldn't load Something with @params: '$error'\n";

Takes in arguments the module name, and optionally parameters to pass to the import internal method.

In scalar context, returns 1 if successful, 0 if not.
In list context, returns 1 if successful, C<(0, "error message")> if not.

=head2 use_lib

Runs a "C<use lib qw(path1 path2)>" at run time instead of compile time.

    use Dancer::ModuleLoader;
    ...
    Dancer::ModuleLoader->use_lib('path1', @other_paths)
        or die "Couldn't perform use lib\n";

    my ($res, $error) = Dancer::ModuleLoader->use_lib('path1', @other_paths);
    $res or die "Couldn't perform use lib : '$error'\n";

Takes in arguments a list of path to be prepended to C<@INC>, in a similar way
than C<use lib>. However, this is performed at run time, so the list of paths
can be generated and dynamic.

In scalar context, returns 1 if successful, 0 if not.
In list context, returns 1 if successful, C<(0, "error message")> if not.

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

=head1 SEE ALSO

L<Module::Load>, L<Module::New::Loader>

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
