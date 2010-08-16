package Dancer::Serializer::Dumper;

use strict;
use warnings;
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
    die "unable to deserialize : $@" if $@;
    return $res;
}

sub content_type {'text/x-data-dumper'}

1;
