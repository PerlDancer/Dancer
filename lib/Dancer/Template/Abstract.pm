package Dancer::Template::Abstract;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: abstract class for Dancer's template engines
$Dancer::Template::Abstract::VERSION = '1.3202';
use strict;
use warnings;
use Carp;

use Dancer::Logger;
use Dancer::Factory::Hook;
use Dancer::FileUtils 'path';
use Dancer::Exception qw(:all);

use base 'Dancer::Engine';

Dancer::Factory::Hook->instance->install_hooks(
    qw/before_template_render after_template_render before_layout_render after_layout_render/
);

# overloads this method to implement the rendering
# args:   $self, $template, $tokens
# return: a string of $template's content processed with $tokens
sub render { confess "render not implemented" }

sub default_tmpl_ext { "tt" }

# Work out the template names to look for; this will be the view name passed
# as-is, and also the view name with the default template extension appended, if
# it did not already end in that.
sub _template_name {
    my ( $self, $view ) = @_;
    my @views = ( $view );
    my $def_tmpl_ext = $self->config->{extension} || $self->default_tmpl_ext();
    push @views, $view .= ".$def_tmpl_ext" if $view !~ /\.\Q$def_tmpl_ext\E$/;
    return @views;
}

sub view {
    my ($self, $view) = @_;

    my $views_dir = Dancer::App->current->setting('views');

    for my $template ($self->_template_name($view)) {
        my $view_path = path($views_dir, $template);
        return $view_path if -f $view_path;
    }

    # No matching view path was found
    return;
}

sub layout {
    my ($self, $layout, $tokens, $content) = @_;

    my $layouts_dir = path(Dancer::App->current->setting('views'), 'layouts');
    my $layout_path;
    for my $layout_name ($self->_template_name($layout)) {
        $layout_path = path($layouts_dir, $layout_name);
        last if -e $layout_path;
    }

    my $full_content;
    if (-e $layout_path) {
        $full_content = Dancer::Template->engine->render(
                                     $layout_path, {%$tokens, content => $content});
    } else {
        $full_content = $content;
        Dancer::Logger::error("Defined layout ($layout) was not found!");
    }
    $full_content;
}

sub apply_renderer {
    my ($self, $view, $tokens) = @_;

    ($tokens, undef) = _prepare_tokens_options($tokens);

    $view = $self->view($view);

    Dancer::Factory::Hook->execute_hooks('before_template_render', $tokens);

    my $content;
    try {
        $content = $self->render($view, $tokens);
    } continuation {
        my ($continuation) = @_;
        # If we have a Route continuation, run the after hook, then
        # propagate the continuation
        Dancer::Factory::Hook->execute_hooks('after_template_render', \$content);
        $continuation->rethrow();
    };

    Dancer::Factory::Hook->execute_hooks('after_template_render', \$content);

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

    Dancer::Factory::Hook->execute_hooks('before_layout_render', $tokens, \$content);

    my $full_content;

    try {
        $full_content = $self->layout($layout, $tokens, $content);
    } continuation {
        my ($continuation) = @_;
        # If we have a Route continuation, run the after hook, then
        # propagate the continuation
        Dancer::Factory::Hook->execute_hooks('after_layout_render', \$full_content);
        $continuation->rethrow();
    };

    Dancer::Factory::Hook->execute_hooks('after_layout_render', \$full_content);

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
    $tokens->{perl_version}   = $];
    $tokens->{dancer_version} = $Dancer::VERSION;
    $tokens->{settings}       = Dancer::Config->settings;

    # If we're processing a request, also add the request object, params and
    # vars as tokens:
    if (my $request = Dancer::SharedData->request) {
        $tokens->{request}        = $request;
        $tokens->{params}         = $request->params;
        $tokens->{vars}           = Dancer::SharedData->vars;
    }

    Dancer::App->current->setting('session')
      and $tokens->{session} = Dancer::Session->get;

    return ($tokens, $options);
}

sub template {
    my ($class, $view, $tokens, $options) = @_;
    my ($content, $full_content);

    my $engine = Dancer::Template->engine;

    # it's important that $tokens is not undef, so that things added to it via
    # a before_template in apply_renderer survive to the apply_layout. GH#354
    $tokens  ||= {};
    $options ||= {};

    if ($view) {
        # check if the requested view exists
        my $view_path = $engine->view($view) || '';
        if ($engine->view_exists($view_path)) {
            $content = $engine->apply_renderer($view, $tokens);
        } else {
            Dancer::Logger::error(
                "Supplied view ($view) not found - $view_path does not exist"
            );
            return Dancer::Error->new(
                          code => 500,
                          message => 'view not found',
                   )->render();
        }
    } else {
        $content = delete $options->{content};
    }

    defined $content and $full_content =
      $engine->apply_layout($content, $tokens, $options);

    defined $full_content
      and return $full_content;

    Dancer::Error->new(
        code    => 404,
        message => "Page not found",
    )->render();
}

sub view_exists { return defined $_[1] &&  -f $_[1] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Template::Abstract - abstract class for Dancer's template engines

=head1 VERSION

version 1.3202

=head1 DESCRIPTION

This class is provided as a base class for each template engine. Any template
engine must inherit from it and provide a set of methods described below.

=head1 TEMPLATE TOKENS

By default Dancer injects some tokens (or variables) to templates. The
available tokens are:

=over 4

=item C<perl_version>

The current running Perl version.

=item C<dancer_version>

The current running Dancer version.

=item C<settings>

Hash to access current application settings.

=item C<request>

Hash to access your current request.

=item C<params>

Hash to access your request parameters.

=item C<vars>

Hash to access your defined variables (using C<vars>).

=item C<session>

Hash to access your session (if you have session enabled)

=back

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

The default behavior of this method is to return the path of the given view,
appending the default template extension (either the value of the C<extension>
setting in the configuration, or the value returned by C<default_tmpl_ext>) if
it is not present in the view name given and no layout template with that exact
name existed.  (In other words, given a layout name C<main>, if C<main> exists
in the layouts dir, it will be used; if not, C<main.tmpl> (where C<tmpl> is the
value of the C<extension> setting, or the value returned by C<default_tmpl_ext>)
will be looked for.)

=item B<view_exists($view_path)>

By default, Dancer::Template::Abstract checks to see if it can find the
view file calling C<view_exists($path_to_file)>. If not, it will
generate a nice error message for the user.

If you are using extending Dancer::Template::Abstract to use a template
system with multiple document roots (like L<Text::XSlate> or
L<Template>), you can override this method to always return true, and
therefore skip this check.

=item B<layout($layout, $tokens, $content)>

The default behavior of this method is to merge a content with a layout.  The
layout file is looked for with similar logic as per C<view> - an exact match
first, then attempting to append the default template extension, if the view
name given did not already end with it.

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

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
