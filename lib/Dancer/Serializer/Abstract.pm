package Dancer::Serializer::Abstract;
our $AUTHORITY = 'cpan:SUKRIA';
# ABSTRACT: Base serialiser class for Dancer
$Dancer::Serializer::Abstract::VERSION = '1.3202';
use strict;
use warnings;
use Carp;
use base 'Dancer::Engine';

sub serialize   { confess 'must be implemented' }
sub deserialize { confess 'must be implemented' }

# must be implemented to declare if the serializer can be used or not
# most of the time, just use :
# Dancer::ModuleLoader->load('Your::Serializer::Deps');
sub loaded {0}

# should be implemented, fallback to text/plain if not
sub content_type {'text/plain'}

# most serializer don't have to overload this one
sub support_content_type {
    my ($self, $ct) = @_;
    return unless $ct;
    my @toks = split ';', $ct;
    $ct = lc($toks[0]);
    return $ct eq $self->content_type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Serializer::Abstract - Base serialiser class for Dancer

=head1 VERSION

version 1.3202

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
