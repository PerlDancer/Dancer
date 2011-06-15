package Dancer::Template::TemplateToolkit;
# ABSTRACT: Template Toolkit wrapper for Dancer

=head1 DESCRIPTION

This class is an interface between Dancer's template engine
abstraction layer and the L<Template> module.

This template engine is recomended for production purposes, but
depends on the Template module.

In order to use this engine, use the template setting:

    template: template_toolkit

This can be done in your config.yml file or directly in your app code
with the B<set> keyword.

Note that by default, Dancer configures the Template::Toolkit engine
to use <% %> brackets instead of its default [% %] brackets.  This can
be changed within your config file - for example:

    template: template_toolkit
    engines:
        template_toolkit:
            start_tag: '[%'
            stop_tag: '%]'

By default, L<Template> is used, but you can configure Dancer to use a
subclass with the C<subclass> option.

    engines:
        template_toolkit:
            subclass: My::Template

=cut

use strict;
use warnings;
use Carp;
use Dancer::Config 'setting';
use Dancer::ModuleLoader;
use Dancer::FileUtils 'path';

use base 'Dancer::Template::Abstract';

my $_engine;

sub init {
    my ($self) = @_;

    my $class = $self->config->{subclass} || "Template";
    croak "$class is needed by Dancer::Template::TemplateToolkit"
      if !$class->can("process") and !Dancer::ModuleLoader->load($class);

    my $charset = setting('charset') || '';
    my @encoding = length($charset) ? ( ENCODING => $charset ) : ();

    my $tt_config = {
        ANYCASE  => 1,
        ABSOLUTE => 1, # revise me
        @encoding,
        %{$self->config},
    };

    my $start_tag = $self->config->{start_tag} || '<%';
    my $stop_tag =
         $self->config->{stop_tag}
      || $self->config->{end_tag}
      || '%>';

    # FIXME looks like if I set START/END tags to TT's defaults, it goes crazy
    # so I only change them if their value is different
    $tt_config->{START_TAG} = $start_tag if $start_tag ne '[%';
    $tt_config->{END_TAG}   = $stop_tag  if $stop_tag  ne '%]';

    $tt_config->{INCLUDE_PATH} = setting('views');

    $_engine = $class->new(%$tt_config);
}


=method render

Check the L<Dancer::Template::Abstract> documentation for this method.

=cut
sub render {
    my ($self, $template, $tokens) = @_;

    if ( ! ref $template ) {
        -f $template or croak "'$template' doesn't exist or not a regular file";
    }

    my $content = "";
    my $charset = setting('charset') || '';
    my @options = length($charset) ? ( binmode => ":encoding($charset)" ) : ();
    $_engine->process($template, $tokens, \$content, @options) or croak $_engine->error;
    return $content;
}

1;


=head1 WRAPPER, META variables, SETs

Dancer already provides a WRAPPER-like ability, which we call a
"layout". The reason we do not use TT's WRAPPER (which also makes it
incompatible with it) is because not all template systems support
it. Actually, most don't.

However, you might want to use it, and be able to define META
variables and regular L<Template::Toolkit> variables.

These few steps will get you there:

=over 4

=item * Disable the layout in Dancer

You can do this by simply commenting (or removing) the C<layout>
configuration in the F<config.yml> file.

=item * Use Template Toolkit template engine

Change the configuration of the template to Template Toolkit:

    # in config.yml
    template: "template_toolkit"

=item * Tell the Template Toolkit engine who's your wrapper

    # in config.yml
    # ...
    engines:
        template_toolkit:
            WRAPPER: layouts/main.tt

=back

Done! Everything will work fine out of the box, including variables
and META variables.

=cut
