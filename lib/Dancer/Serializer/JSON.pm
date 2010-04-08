package Dancer::Serializer::JSON;

use strict;
use warnings;
use Dancer::ModuleLoader;
use base 'Dancer::Serializer::Abstract';

my $_loaded;

sub init {
    die 'JSON is needed and is not installed'
        unless Dancer::ModuleLoader->load('JSON');
    $_loaded = 1;
}

sub serialize {
    my ( $self, $entity ) = @_;
    if ($_loaded) {
        JSON::encode_json($entity);
    }
    else {
        # die ?
    }
}

sub deserialize {
    my ( $self, $content ) = @_;
    if ($_loaded) {
        JSON::decode_json($content);
    }else{
        # die ?
    }
}

sub content_type {'application/json'}

1;
