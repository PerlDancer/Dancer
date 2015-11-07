package Dancer::Serializer::Dumper;
our $AUTHORITY = 'cpan:SUKRIA';
# ABSTRACT: Data::Dumper serialisation for Dancer
$Dancer::Serializer::Dumper::VERSION = '1.3202';
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

=encoding UTF-8

=head1 NAME

Dancer::Serializer::Dumper - Data::Dumper serialisation for Dancer

=head1 VERSION

version 1.3202

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
