package Dancer::Serializer::JSON;

use strict;
use warnings;
use JSON;
use base 'Dancer::Serializer::Abstract';

sub serialize {
    my ($self, $entity) = @_;
    JSON::encode_json $entity;
}

sub deserialize {
    my ($self, $content) = @_;
    JSON::decode_json $content;
}

sub content_type {
    "application/json"
}

1;
