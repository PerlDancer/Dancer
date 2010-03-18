package Dancer::Serializer::Mutable;

use strict;
use warnings;

use base 'Dancer::Serializer::Abstract';
use Dancer::SharedData;

my $serializer = {
    'text/x-yaml'      => 'YAML',
    'text/html'        => 'YAML',
    'text/xml'         => 'XML',
    'text/x-json'      => 'JSON',
    'application/json' => 'JSON',
};

my $loaded_serializer = {};

sub _find_content_type {
    my $self = shift;

    # first content type, second accept and final default
    my %content_types;
    my ( $request, $params );
    $request = Dancer::SharedData->request;
    if ($request) {
        $params = $request->params;
    }

    if ( $request->{content_type} ) {
        $content_types{ $request->{content_type} } = 3;
    }

    if ( $params && $params->{content_type} ) {
        $content_types{ $params->{content_type} } = 2;
    }

    if ( $request->{accept_type} ) {
        $content_types{ $request->{accept_type} } = 1;
    }

    $content_types{'application/json'} = 0;

    return [
        sort { $content_types{$b} <=> $content_types{$a} }
            keys %content_types
    ];
}

sub serialize {
    my ($self, $entity) = @_;
    my $serializer = $self->_load_serializer();
    return $serializer->serialize($entity);
}

sub deserialize {
    my ($self, $content) = @_;
    my $serializer = $self->_load_serializer;
    return $serializer->deserialize($content);
}

sub content_type {
    my $self = shift;
    shift @{$self->_find_content_type};
}

sub _load_serializer {
    my $self = shift;

    my $content_types = $self->_find_content_type();

    foreach my $ct (@$content_types) {
        if ( exists $serializer->{$ct} ) {
            my $module = "Dancer::Serializer::" . $serializer->{$ct};
            if ( !exists $loaded_serializer->{$module} ) {
                if ( Dancer::ModuleLoader->load($module) ) {
                    my $serializer_object = $module->new;
                    $loaded_serializer->{$module} = $serializer_object;
                }
            }
            return $loaded_serializer->{$module};
        }
    }
}

1;
