package Dancer::Template::TemplateToolkit;

use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer::FileUtils 'path';

use base 'Dancer::Template::Abstract';

my $_engine;

sub init {
    my ($self) = @_;

    die "Template is needed by Dancer::Template::TemplateToolkit"
      unless Dancer::ModuleLoader->load('Template');
    my $tt_config = {
        START_TAG => '<%',
        END_TAG   => '%>',
        ANYCASE   => 1,
        ABSOLUTE  => 1,
    };

    $tt_config->{INCLUDE_PATH} = path($self->{settings}{'appdir'}, 'views')
      if $self->{settings} && $self->{settings}{'appdir'};

    $_engine = Template->new(%$tt_config);
}

sub render($$$) {
    my ($self, $template, $tokens) = @_;
    die "'$template' is not a regular file"
      if !ref($template) && (!-f $template);

    my $content = "";
    $_engine->process($template, $tokens, \$content) or die $_engine->error;
    return $content;
}

1;
__END__

=pod

=head1 NAME

Dancer::Template::TemplateToolkit - Template Toolkit wrapper for Dancer

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<Template> module.

This template engine is recomended for production purproses, but depends on the
Template module.

In order to use this engine, set the following setting as the following:

    template: template_toolkit

This can be done in your config.yml file or directly in your app code with the
B<set> keyword.

Note that Dancer configures the Template::Toolkit engine to use <% %> brackets
instead of its default [% %] brackets.

=head1 SEE ALSO

L<Dancer>, L<Template>

=head1 AUTHOR

This module has been written by Alexis Sukrieh

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=cut
