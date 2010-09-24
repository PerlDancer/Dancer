package Dancer::Template::Abstract;

use strict;
use warnings;
use Dancer::FileUtils 'path';
use base 'Dancer::Engine';

# Overloads this method to implement the rendering
# args:   $self, $template, $tokens
# return: a string of $template's content processed with $tokens
sub render { die "render not implemented" }

sub default_tmpl_ext { "tt" };

sub view {
    my ($self, $view) = @_;

    my $def_tmpl_ext = $self->default_tmpl_ext();
    $view .= ".$def_tmpl_ext" if $view !~ /\.${def_tmpl_ext}$/;

    my $app = Dancer::App->current;
    return path($app->setting('views'), $view);
}

sub layout {
    my ($self, $layout, $tokens, $content) = @_;

    my $app = Dancer::App->current;
    my $def_tmpl_ext = $self->default_tmpl_ext();
    $layout .= ".$def_tmpl_ext" if $layout !~ /\.${def_tmpl_ext}$/;
    $layout = path($app->setting('views'), 'layouts', $layout);

    my $full_content =
      Dancer::Template->engine->render($layout,
        {%$tokens, content => $content});
    $full_content;
}

1;
__END__

=pod

=head1 NAME

Dancer::Template::Abstract - abstract class for Dancer's template engines

=head1 DESCRIPTION

This class is provided as a base class for each template engine. Any template
engine must inherit from it and provide a set of methods described below.

=head1 INTERFACE

=over 4

=item B<init()>

The template engine can overload this method if some initialization stuff has to
be done before the template engine is used.

The base class provides a plain init() method that only returns true.

=item B<default_tmpl_ext()>

Template class that inherits this class should override this method to return a default template
extension, example: for Template::Toolkit it returns "tt" and for HTML::Mason it returns "mason". 
So when you call C<template 'index';> in your dispatch code, Dancer will look for a file 'index.tt'
or 'index.mason' based on the template you use.

Note 1: when returning the extension string, please do not add a dot in front of the extension 
as Dancer will do that. 
Note 2: for backwords compatibility abstract class returns "tt" instead of throwing
an exception 'method not implemented'.

=item B<view($view)>

The default behavior of this method is to return the path of the given view.

=item B<layout($layout, $tokens, $content)>

The default behavior of this method is to merge a content with a layout.

=item B<render($self, $template, $tokens)>

This method must be implemented by the template engine. Given a template and a
set of tokens, it returns a processed string.

If C<$template> is a reference, it's assumed to be a reference to a string that
contains the template itself. If it's not a reference, it's assumed to be the
path to template file, as a string. The render method will then have to open it
and read its content (Dancer::FileUtils::read_file_content does that job).

This method's return value must be a string which is the result of the
interpolation of C<$tokens> in C<$template>.

If an error occurs, the method should trigger an exception with C<die()>.

Examples :

    # with a template as a file
    $content = $engine->render('/my/template.txt', { var => 42 };

    # with a template as a scalar
    my $template = "here is <% var %>";
    $content = $engine->render(\$template, { var => 42 });

=back

=head1 AUTHOR

This module has been written by Alexis Sukrieh, see L<Dancer> for details.

=cut
