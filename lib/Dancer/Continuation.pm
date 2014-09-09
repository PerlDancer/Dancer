package Dancer::Continuation;
BEGIN {
  $Dancer::Continuation::AUTHORITY = 'cpan:SUKRIA';
}
$Dancer::Continuation::VERSION = '1.3127';
use strict;
use warnings;
use Carp;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub throw { die shift }

sub rethrow { die shift }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Continuation

=head1 VERSION

version 1.3127

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
