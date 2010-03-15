package Dancer::Serializer::Base;

use strict;
use warnings;

use base 'Dancer::Engine';
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
    my $request = Dancer::SharedData->request;
    my $params  = Dancer::SharedData->request->params;

    if ( $request->{content_type} ) {
        $content_types{ $request->{content_type} } = 3;
    }

    if ( $params->{content_type} ) {
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
    my $self = shift;

    my $request = Dancer::SharedData->request;

    if ($request->{method} eq 'PUT' || $request->{method} eq 'POST') {
        my $rdata = $request->{body};
        my $serializer = $self->_load_serializer;
        my $previous = Dancer::SharedData->request->params;
        $request->{params} = {%$previous, %{$serializer->deserialize($rdata)}};
    }
}

sub _load_serializer {
    my $self = shift;

    my $content_types = $self->_find_content_type();

    foreach my $ct (@$content_types) {
        if (exists $serializer->{$ct}) {
            my $module = "Dancer::Serializer::".$serializer->{$ct};
            if (!exists $loaded_serializer->{$module}){
                 if (Dancer::ModuleLoader->load($module)) {
                     my $object;
                     eval { $object= $module->new();};
                     $loaded_serializer->{$module} = $object;
                 }
            }
            return $loaded_serializer->{$module};
        }
    }
}

1;
