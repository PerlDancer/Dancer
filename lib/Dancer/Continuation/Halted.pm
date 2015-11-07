package Dancer::Continuation::Halted;
our $AUTHORITY = 'cpan:SUKRIA';
# ABSTRACT: Halted internal exception class for Dancer
$Dancer::Continuation::Halted::VERSION = '1.3202';
use strict;
use warnings;
use Carp;

use base qw(Dancer::Continuation);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Continuation::Halted - Halted internal exception class for Dancer

=head1 VERSION

version 1.3202

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
