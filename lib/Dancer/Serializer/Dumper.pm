package Dancer::Serializer::Dumper;
# ABSTRACT: Data::Sumper serializer engine

=head1 ABSTRACT

Perl dumper format serializer.

=cut

use strict;
use warnings;
use Carp;
use base 'Dancer::Serializer::Abstract';
use Data::Dumper;

=method from_dumper

Subroutine that converts a Dumper string in the respective data
structure.

=cut
sub from_dumper {
    my ($string) = @_;
    my $s = Dancer::Serializer::Dumper->new;
    $s->deserialize($string);
}

=method to_dumper

Subroutine that converts a data structure in a Dumper string.

=cut
sub to_dumper {
    my ($data) = @_;
    my $s = Dancer::Serializer::Dumper->new;
    $s->serialize($data);
}

=method serialize

Method that converts a data structure in a Dumper string.

=cut
sub serialize {
    my ($self, $entity) = @_;
    {
        local $Data::Dumper::Purity = 1;
        return Dumper($entity);
    }
}

=method deserialize

Method that converts a Dumper string in a Perl data structure.

=cut
sub deserialize {
    my ($self, $content) = @_;
    my $res = eval "my \$VAR1; $content";
    croak "unable to deserialize : $@" if $@;
    return $res;
}

=method content_type

Returns Perl data dumper content type string.

=cut
sub content_type {'text/x-data-dumper'}

1;
