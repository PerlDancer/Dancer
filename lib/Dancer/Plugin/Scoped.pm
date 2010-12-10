package Dancer::Plugin::Scoped;
use base 'Exporter';
@EXPORT = qw( scoped );
use warnings;
use strict;

our $VERSION = '0.01';


sub scoped (&) {
	my ($code) = @_;
	my $caller = caller;
	return sub {
	no strict 'refs';
	while (my ($k, $v) = each %{Dancer::SharedData->request->params}) {
		${"$caller\::$k"} = $v;
	}
	$code->(@_);
	};
}

=head1 NAME

Dancer::Plugin::Scoped - Allows to set params variables in scope of route handler

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Scoped;

    any '/' => scoped {
       our ($page, $test);
       template $page, { test => $test };
    };

    $page, $test - these variables will be set according to params data, e.g. $page is a syntactic
    alias to params->{page}.

=head1 EXPORT

scoped

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

=head1 AUTHOR

Roman Galeev, C<< <jamhedd at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-scoped at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-Scoped>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Scoped

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-Scoped>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-Scoped>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-Scoped>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-Scoped/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Roman Galeev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Dancer::Plugin::Scoped
