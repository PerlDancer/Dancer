package Dancer::Template::Abstract;

use strict;
use warnings;
use Carp;
use Dancer::FileUtils 'path';
use base 'Dancer::Engine';

# Overloads this method to implement the rendering
# args:   $self, $template, $tokens
# return: a string of $template's content processed with $tokens
sub render { confess "render not implemented" }

sub default_tmpl_ext { "tt" }

sub _template_name {
    my ( $self, $view ) = @_;
    my $def_tmpl_ext = $self->config->{extension} || $self->default_tmpl_ext();
    $view .= ".$def_tmpl_ext" if $view !~ /\.${def_tmpl_ext}$/;
}

sub view {
    my ($self, $view) = @_;

    $view = $self->_template_name($view);

    return path(Dancer::App->current->setting('views'), $view);
}

sub layout {
    my ($self, $layout, $tokens, $content) = @_;

    my $layout_name = $self->_template_name($layout);
    my $layout_path = path(Dancer::App->current->setting('views'), 'layouts', $layout_name);

    my $full_content =
      Dancer::Template->engine->render($layout_path,
        {%$tokens, content => $content});
    $full_content;
}

sub apply_renderer {
    my ($self, $view, $tokens) = @_;

    ($tokens, undef) = _prepare_tokens_options($tokens);

    $view = $self->view($view);
    -r $view or return;

    $_->($tokens) for (@{Dancer::App->current->registry->hooks->{before_template}});

    my $content = $self->render($view, $tokens);

    # make sure to avoid ( undef ) in list context return
    defined $content
      and return $content;
    return;
}

sub apply_layout {
    my ($self, $content, $tokens, $options) = @_;

    ($tokens, $options) = _prepare_tokens_options($tokens, $options);

    # If 'layout' was given in the options hashref, use it if it's a true value,
    # or don't use a layout if it was false (0, or undef); if layout wasn't
    # given in the options hashref, go with whatever the current layout setting
    # is.
    my $layout =
      exists $options->{layout}
      ? ($options->{layout} ? $options->{layout} : undef)
      : Dancer::App->current->setting('layout');

    defined $content or return;

    defined $layout or return $content;

    my $full_content =
      $self->layout($layout, $tokens, $content);
    # make sure to avoid ( undef ) in list context return
    defined $full_content
      and return $full_content;
    return;
}

sub _prepare_tokens_options {
    my ($tokens, $options) = @_;

    $options ||= {};

    # these are the default tokens provided for template processing
    $tokens ||= {};
    $tokens->{dancer_version} = $Dancer::VERSION;
    $tokens->{settings}       = Dancer::Config->settings;
    $tokens->{request}        = Dancer::SharedData->request;
    $tokens->{params}         = Dancer::SharedData->request->params;

    Dancer::App->current->setting('session')
      and $tokens->{session} = Dancer::Session->get;

    return ($tokens, $options);
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

Note 2: for backwards compatibility abstract class returns "tt" instead of throwing
an exception 'method not implemented'.

User would be able to change the default extension using the
C<<extension>> configuration variable on the template
configuration. For example, for the default (C<Simple>) engine:

     template: "simple"
     engines:
       simple:
         extension: 'tmpl'

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
