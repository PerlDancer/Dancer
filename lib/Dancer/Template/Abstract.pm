package Dancer::Template::Abstract;

use strict;
use warnings;
use base 'Dancer::Engine';

# Overloads this method to implement the rendering
# args:   $self, $template, $tokens
# return: a string of $template's content processed with $tokens
sub render($$$) { die "render not implemented" }

1;
__END__

=pod

=head1 NAME

Dancer::Template::Abstract - abstract class for Dancer's template engines

=head1 DESCRIPTION

This class is provided as a mother class for each template engine. Any template
engine must inherits from it and have to provide a set of methods.

=head1 INTERFACE

=over 4

=item B<init()>

The template engine can overload this method if some initialization stuff has to
be done before the template engine is used.

The mother class provide a dumb init() method that returns true and do nothing.

=item B<render($self, $template, $tokens)>

This method must be implemented by the template engine. Given a template and a
tokens set, it returns a processed string.

If $template is a reference, it's assumed it's a reference to a string that
contains the template itself. If it's not a reference, it's assumed that the
string is a path to template file. The render method will then have to open it a
read its content (Dancer::FileUtils::read_file_content does that job).

This method's return value must be a string which is the result of the
interpolation of $tokens in $template.

If an error occur, the method should trigger an exception with die.

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
