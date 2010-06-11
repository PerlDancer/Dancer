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
my $_content_type;

sub _find_content_type {
    my ($self, $request) = @_;

    # first content type, second accept and final default
    my %content_types;
    my $params;

    if ($request) {
        $params = $request->params;
    }

    my $method = $request->method;

    if ($method =~ /^(?:POST|PUT)$/) {
        if ($request->{content_type}) {
            $content_types{$request->{content_type}} = 4;
        }

        if ($params && $params->{content_type}) {
            $content_types{$params->{content_type}} = 3;
        }
    }

    if ($request->{accept}) {
        $content_types{$request->{accept}} = 2;
    }
    if ($request->{'accept_type'}) {
        $content_types{$request->{accept_type}} = 1;
    }

    $content_types{'application/json'} = 0;

    return [
        sort { $content_types{$b} <=> $content_types{$a} }
          keys %content_types
    ];
}

sub serialize {
    my ($self, $entity) = @_;
    my $request = Dancer::SharedData->request;
    my $serializer = $self->_load_serializer($request);
    return $serializer->serialize($entity);
}

sub deserialize {
    my ($self, $content, $request) = @_;
    my $serializer = $self->_load_serializer($request);
    return $serializer->deserialize($content, $request);
}

sub content_type {
    my $self = shift;
    $_content_type;
}

sub support_content_type {
    my ($self, $ct) = @_;
    grep /^$ct$/, keys %$serializer;
}

sub _load_serializer {
    my ($self, $request) = @_;

    my $content_types = $self->_find_content_type($request);
    foreach my $ct (@$content_types) {
        if ( exists $serializer->{$ct} ) {
            my $module = "Dancer::Serializer::" . $serializer->{$ct};
            if ( !exists $loaded_serializer->{$module} ) {
                if ( Dancer::ModuleLoader->load($module) ) {
                    my $serializer_object = $module->new;
                    $loaded_serializer->{$module} = $serializer_object;
                }
            }
            $_content_type = $ct;
            return $loaded_serializer->{$module};
        }
    }
}

1;
__END__

=head1 NAME

Dancer::Serializer::Mutable

=head1 SYNOPSIS

=head1 DESCRIPTION

This serializer will try find the best (de)serializer for a given request.
For this, it will go through:

=over 4

=item

The B<content_type> from the request headers

=item

the B<content_type> parameter from the URL

=item

the B<accept> from the request headers

=item

The default is B<application/json>

=back

=head2 METHODS

=over 4

=item B<serialize>

Serialize a data structure to a YAML structure.

=item B<deserialize>

Deserialize a YAML structure to a data structure

=item B<content_type>

Return 'application/json'

=back
