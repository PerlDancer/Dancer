package Dancer::Serializer::Dumper;

use strict;
use warnings;
use Carp;
use base 'Dancer::Serializer::Abstract';
use Data::Dumper;

# we want to eval serialized strings
$Data::Dumper::Purity = 1;

sub from_dumper {
    my ($string) = @_;
    my $s = Dancer::Serializer::Dumper->new;
    $s->deserialize($string);
}

sub to_dumper {
    my ($data) = @_;
    my $s = Dancer::Serializer::Dumper->new;
    $s->serialize($data);
}

sub serialize {
    my ($self, $entity) = @_;
    {
        local $Data::Dumper::Purity = 1;
        return Dumper($entity);
    }
}

sub deserialize {
    my ($self, $content) = @_;
    my $res = eval "my \$VAR1; $content";
    croak "unable to deserialize : $@" if $@;
    return $res;
}

sub content_type {'text/x-data-dumper'}

1;

__END__

=head1 NAME

Dancer::Serializer::Dumper - Data::Dumper serializer

=head1 SYNOPSIS

    use Dancer::Serializer::Dumper;

    my $serializer = Data::Serializer::Dumper->new;
    my $dump       = $serializer->serialize( { name => 'John Doe' } );
    my $hash       = $serializer->deserialize($dump);

=head1 DESCRIPTION

This engine allows you to serialize your data to L<Data::Dumper> and deserialize
from L<Data::Dumper>.

You can configure it in your C<config.yml> file:

    serializer: Dumper

or directly in your app code with the B<set> keyword.

    set serializer => 'Dumper';

=head2 METHODS

=head3 serialize

Serialize a data structure to a Data::Dumper structure.

=head3 deserialize

Deserialize a Data::Dumper structure to a data structure.

=head3 content_type

Return 'text/x-data-dumper'

