package Dancer::Template::Abstract;
# ABSTRACT: abstract class for Dancer's template engines
use strict;
use warnings;
use Carp;

use Dancer::Factory::Hook;
use Dancer::Deprecation;
use Dancer::FileUtils 'path';

use base 'Dancer::Engine';

Dancer::Factory::Hook->instance->install_hooks(
    qw/before_template_render after_template_render before_layout_render after_layout_render/
);

=method init()

The template engine can overload this method if some initialization
stuff has to be done before the template engine is used.

The base class provides a plain init() method that only returns true.

=method render($self, $template, $tokens)

This method must be implemented by the template engine. Given a
template and a set of tokens, it returns a processed string.

If C<$template> is a reference, it's assumed to be a reference to a
string that contains the template itself. If it's not a reference,
it's assumed to be the path to template file, as a string. The render
method will then have to open it and read its content
(Dancer::FileUtils::read_file_content does that job).

This method's return value must be a string which is the result of the
interpolation of C<$tokens> in C<$template>.

If an error occurs, the method should trigger an exception with C<die()>.

Examples :

    # with a template as a file
    $content = $engine->render('/my/template.txt', { var => 42 };

    # with a template as a scalar
    my $template = "here is <% var %>";
    $content = $engine->render(\$template, { var => 42 });

=cut
sub render { confess "render not implemented" }


=method default_tmpl_ext()

Template class that inherits this class should override this method to
return a default template extension, example: for Template::Toolkit it
returns "tt" and for HTML::Mason it returns "mason".  So when you call
C<template 'index';> in your dispatch code, Dancer will look for a
file 'index.tt' or 'index.mason' based on the template you use.

B<Note 1:> when returning the extension string, please do not add a
dot in front of the extension as Dancer will do that.

B<Note 2:> for backwards compatibility abstract class returns "tt"
instead of throwing an exception 'method not implemented'.

User would be able to change the default extension using the
C<<extension>> configuration variable on the template
configuration. For example, for the default (C<Simple>) engine:

     template: "simple"
     engines:
       simple:
         extension: 'tmpl'

=cut
sub default_tmpl_ext { "tt" }

=method view($view)

The default behavior of this method is to return the path of the given
view.

=cut
sub view {
    my ($self, $view) = @_;

    $view = $self->_template_name($view);

    return path(Dancer::App->current->setting('views'), $view);
}

=method layout($layout, $tokens, $content)

The default behavior of this method is to merge a content with a
layout.

=cut
sub layout {
    my ($self, $layout, $tokens, $content) = @_;

    my $layout_name = $self->_template_name($layout);
    my $layout_path = path(Dancer::App->current->setting('views'), 'layouts', $layout_name);

    my $full_content =
      Dancer::Template->engine->render($layout_path,
        {%$tokens, content => $content});
    $full_content;
}

=method apply_renderer($view, $tokens)

Applies the template renderer, given a view (name of the template to
use) and the tokens to be interpolated.

=cut
sub apply_renderer {
    my ($self, $view, $tokens) = @_;

    ($tokens, undef) = _prepare_tokens_options($tokens);

    $view = $self->view($view);

    Dancer::Factory::Hook->execute_hooks('before_template_render', $tokens);

    my $content = $self->render($view, $tokens);

    Dancer::Factory::Hook->execute_hooks('after_template_render', \$content);

    # make sure to avoid ( undef ) in list context return
    defined $content
      and return $content;
    return;
}

=method apply_layout($content, $tokens, $options)

Apply a template layout using the supplied contents and interpolating
the supplied tokens.

In the options the key C<layout> can be set to a true value stating a
layout should be used or to a false value, stating a layout should not
be used. If it doesn't exist in the C<options> hash ref the current
C<layout> setting will be used.

=cut
sub apply_layout {
    my ($self, $content, $tokens, $options) = @_;

    ($tokens, $options) = _prepare_tokens_options($tokens, $options);

    my $layout =
      exists $options->{layout}
      ? ($options->{layout} ? $options->{layout} : undef)
      : Dancer::App->current->setting('layout');

    defined $content or return;

    defined $layout or return $content;

    Dancer::Factory::Hook->execute_hooks('before_layout_render', $tokens, \$content);

    my $full_content =
      $self->layout($layout, $tokens, $content);

    Dancer::Factory::Hook->execute_hooks('after_layout_render', \$full_content);

    # make sure to avoid ( undef ) in list context return
    defined $full_content
      and return $full_content;
    return;
}

=method template($view, $tokens, $options)

Applies the template engine renderer and layout (calls
C<apply_renderer> and C<apply_layout>) with the supplied parameters.

=cut
sub template {
    my ($class, $view, $tokens, $options) = @_;
    my ($content, $full_content);

    # it's important that $tokens is not undef, so that things added to it via
    # a before_template in apply_renderer survive to the apply_layout. GH#354
    $tokens  ||= {};
    $options ||= {};

    $content = $view ? Dancer::Template->engine->apply_renderer($view, $tokens)
                     : delete $options->{content};

    defined $content and $full_content =
      Dancer::Template->engine->apply_layout($content, $tokens, $options);

    defined $full_content
      and return $full_content;

    Dancer::Error->new(
        code    => 404,
        message => "Page not found",
    )->render();
}


# privates

sub _prepare_tokens_options {
    my ($tokens, $options) = @_;

    $options ||= {};

    # these are the default tokens provided for template processing
    $tokens ||= {};
    $tokens->{perl_version}   = $];
    $tokens->{dancer_version} = $Dancer::VERSION;
    $tokens->{settings}       = Dancer::Config->settings;
    $tokens->{request}        = Dancer::SharedData->request;
    $tokens->{params}         = Dancer::SharedData->request->params;
    $tokens->{vars}           = Dancer::SharedData->vars;

    Dancer::App->current->setting('session')
      and $tokens->{session} = Dancer::Session->get;

    return ($tokens, $options);
}

sub _template_name {
    my ( $self, $view ) = @_;
    my $def_tmpl_ext = $self->config->{extension} || $self->default_tmpl_ext();
    $view .= ".$def_tmpl_ext" if $view !~ /\.\Q$def_tmpl_ext\E$/;
    return $view;
}


sub _render_with_layout {
    my ($class, $content, $tokens, $options) = @_;

    Dancer::Deprecation::deprecated(
        feature => 'render_with_layout',
        version => '1.3000',
        fatal   => 1,
        reason  => "use the 'engine' keyword to get the template engine, and use 'apply_layout' on the result",
    );
}

1;
__END__


=head1 DESCRIPTION

This class is provided as a base class for each template engine. Any
template engine must inherit from it and provide a set of methods
described below.

=cut

