package Dancer::Template::TemplateToolkit;

use strict;
use warnings;
use Dancer::ModuleLoader;

use base 'Dancer::Template::Abstract';

my $_engine;

sub init {
    die "Template is needed by Dancer::Template::TemplateToolkit"
        unless Dancer::ModuleLoader->load('Template');
    my $tt_config = {
        START_TAG => '<%',
        END_TAG => '%>',
        ANYCASE => 1,
    };
    $_engine = Template->new(%$tt_config);
}

sub render($$$) {
    my ($self, $template, $tokens) = @_;
    die "'$template' is not a regular file" 
        if !ref($template) && (! -f $template);

    my $content = "";
    $_engine->process($template, $tokens, \$content);
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

=head1 SEE ALSO

L<Dancer>, L<Template>

=head1 AUTHOR

This module has been written by Alexis Sukrieh

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=cut
