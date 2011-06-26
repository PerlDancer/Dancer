package Dancer::Serializer::Abstract;
# ABSTRACT: interface for serializer engines
use strict;
use warnings;
use Carp;
use base 'Dancer::Engine';

=method serialize

This method that all serializers should implement receive a reference
to a Perl structure and should return a string with the serialized
data.

=cut
sub serialize   { confess 'must be implemented' }

=method deserialize

This method that all serializers should implement receive a string
with some serialized data, and should return a reference to a Perl
structure that represents that data.

=cut
sub deserialize { confess 'must be implemented' }

=method loaded

Must be implemented to delcare if the serializer can be used or not
most of the time, just use:

   Dancer::ModuleLoader->load('Your::Serializer::Deps');

=cut
sub loaded { 0 }

=method content_type

Should be implemented, returning the content type for the serialized string.
Fallbacks to text/plain if not.

=cut
sub content_type {'text/plain'}

=method support_content_type

Most serializer don't have to overload this one. The method receives a
content type string and should return a true value if the serializer
is able to deserialize it.

=cut
sub support_content_type {
    my ($self, $ct) = @_;
    return unless $ct;
    my @toks = split ';', $ct;
    $ct = lc($toks[0]);
    return $ct eq $self->content_type;
}

1;
__END__

=head1 DESCRIPTION

Abstract class for all serializer engines.

=cut

