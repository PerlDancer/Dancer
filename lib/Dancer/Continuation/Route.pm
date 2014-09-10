package Dancer::Continuation::Route;
BEGIN {
  $Dancer::Continuation::Route::AUTHORITY = 'cpan:SUKRIA';
}
$Dancer::Continuation::Route::VERSION = '1.3129';
use strict;
use warnings;
use Carp;

use base qw(Dancer::Continuation);

# A Dancer::Continuation::Route is a continuation exception, that is caught as
# route execution level (see Dancer::Route::run). It may store a return_value, that
# will be recovered from the continuation catcher, and stored as the returning
# content.

sub return_value { $#_ ? $_[0]->{return_value} = $_[1] : $_[0]->{return_value} }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Continuation::Route

=head1 VERSION

version 1.3129

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
