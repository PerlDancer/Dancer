package Dancer::Serializer::Dumper;

use strict;
use warnings;
use base 'Dancer::Serializer::Abstract';
use Data::Dumper;

sub serialize {
    my ($self, $entity) = @_;
    {
        local $Data::Dumper::Purity = 1;
        return Dumper($entity);
    }
}

sub deserialize {
    my ($self, $content) = @_;
    eval "$content";
}

sub content_type { 'text/plain' }

1;
