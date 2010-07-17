package Dancer::Template::Abstract;

use strict;
use warnings;
use Dancer::FileUtils 'path';
use base 'Dancer::Engine';

# Overloads this method to implement the rendering
# args:   $self, $template, $tokens
# return: a string of $template's content processed with $tokens
sub render($$$) { die "render not implemented" }

sub view {
    my ($self, $view) = @_;
    $view .= ".tt" if $view !~ /\.tt$/;
    return path(Dancer::Config::setting('views'), $view);
}

sub layout {
    my ($self, $layout, $tokens, $content) = @_;

    $layout .= '.tt' if $layout !~ /\.tt/;
    $layout = path(Dancer::Config::setting('views'), 'layouts', $layout);

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
