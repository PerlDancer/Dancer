package Dancer::Serializer::Dumper;
# ABSTRACT: Data::Dumper serialisation for Dancer

use strict;
use warnings;
use Carp;
use base 'Dancer::Serializer::Abstract';
use Data::Dumper;
use Dancer::Exception qw(:all);

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
    raise core_serializer => "unable to deserialize : $@" if $@;
    return $res;
}

sub content_type {'text/x-data-dumper'}

1;

__END__

=pod

=head1 DESCRIPTION

This serializer serializes data structures with L<Data::Dumper>, and
deserializes them by passing the serialized text to Perl's C<eval>.

=head1 WARNING - DO NOT USE THIS AS A SERIALIZER

B<Deserializing with this module executes the input as Perl code.> Setting

    serializer: Dumper

in your config means that any client which can send a request with a
C<Content-Type> of C<text/x-data-dumper> gets to run arbitrary Perl in your
application's process, as the user your application runs as. There is no
sandbox, no taint check and no validation: C<deserialize> is a bare
C<eval "my $VAR1; $content">, and C<$content> is the request body.

This is not a hardening opportunity or a configuration mistake; it is what
C<Data::Dumper> round-tripping fundamentally is. Data::Dumper's own
documentation says the same thing about C<eval>ing its output.

Do not use C<Dumper> as your application's serializer on anything that
accepts requests you do not fully control. Use L<Dancer::Serializer::JSON>
instead - it is the sensible default for REST-ish applications, and the
L<Mutable|Dancer::Serializer::Mutable> serializer deliberately does not
offer C<Dumper> at all.

The C<to_dumper> direction (serializing) is harmless in itself, but emitting
C<text/x-data-dumper> encourages clients to C<eval> what you send them, so
it is a poor choice for a wire format regardless.

Dancer 2 removed this serializer from core for these reasons; it is retained
here only for backwards compatibility with existing applications, as Dancer 1
is in maintenance mode. It may be removed in a future release.

=head1 METHODS

=head2 serialize

Serializes a data structure with L<Data::Dumper>, with
C<$Data::Dumper::Purity> enabled.

=head2 deserialize

Deserializes a L<Data::Dumper> string by C<eval>ing it. B<This executes the
input as Perl code> - see L</"WARNING - DO NOT USE THIS AS A SERIALIZER">.

=head2 content_type

Returns C<text/x-data-dumper>.

=head1 SEE ALSO

L<Dancer::Serializer::JSON>, L<Dancer::Serializer::Mutable>,
L<Dancer::Serializer>

=cut
