package Dancer::Continuation::Route;
our $AUTHORITY = 'cpan:SUKRIA';
# ABSTRACT: Internal exception class for Route exceptions in Dancer.
$Dancer::Continuation::Route::VERSION = '1.3202';
use strict;
use warnings;
use Carp;

use base qw(Dancer::Continuation);


sub return_value { $#_ ? $_[0]->{return_value} = $_[1] : $_[0]->{return_value} }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Continuation::Route - Internal exception class for Route exceptions in Dancer.

=head1 VERSION

version 1.3202

=head1 METHODS

=head2 return_value

A Dancer::Continuation::Route is a continuation exception, that is caught as
route execution level (see Dancer::Route::run). It may store a return_value, that
will be recovered from the continuation catcher, and stored as the returning
content.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
