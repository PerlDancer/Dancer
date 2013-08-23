package Dancer::Serializer::Mutable;

use strict;
use warnings;

use base 'Dancer::Serializer::Abstract', 'Exporter';
use Dancer::SharedData;

our @EXPORT_OK = qw/ template_or_serialize /;

my $serializer = {
    'text/x-yaml'      => 'YAML',
    'text/html'        => 'YAML',
    'text/xml'         => 'XML',
    'text/x-json'      => 'JSON',
    'application/json' => 'JSON',
};

my $loaded_serializer = {};
my $_content_type;

sub template_or_serialize {
    my( $template, $data ) = @_;

    my( $content_type ) = @{ _find_content_type(Dancer::SharedData->request) };

    # TODO the accept value coming from the browser can 
    # be quite complex (e.g., 
    # text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    # ), but that simple heuristic should be good enough
    # for most cases
    if ( $content_type =~ qr#text/html# ) {
        return Dancer::template(@_);
    }

    return $data;
}

sub _find_content_type {
    my $request = shift;

    my $params;

    if ($request) {
        $params = $request->params;
    }

    # first content type, second accept and final default
    # we push in @content_types by order of desirability
    # I.e.: we want $content_types[0] more than $content_types[1]
    my @content_types;

    my $method = $request->method;

    if ($method =~ /^(?:POST|PUT|GET)$/) {
        push @content_types, $request->{content_type} 
            if $request->{content_type};

        push @content_types, $params->{content_type} 
            if $params && $params->{content_type};
    }
    
    push @content_types, $request->{accept} 
        if $request->{accept};
    
    push @content_types, $request->{accept_type} 
        if $request->{'accept_type'};

    push @content_types, 'application/json';

    # remove duplicates
    my %seen;
    return [ grep { not $seen{$_}++ } @content_types ];
}

sub serialize {
    my ($self, $entity) = @_;
    my $request    = Dancer::SharedData->request;
    my $serializer = $self->_load_serializer($request);
    return $serializer->serialize($entity);
}

sub deserialize {
    my ($self, $content) = @_;
    my $request    = Dancer::SharedData->request;
    my $serializer = $self->_load_serializer($request);
    return $serializer->deserialize($content);
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

    my $content_types = _find_content_type($request);
    foreach my $ct (@$content_types) {
        if (exists $serializer->{$ct}) {
            my $module = "Dancer::Serializer::" . $serializer->{$ct};
            if (!exists $loaded_serializer->{$module}) {
                if (Dancer::ModuleLoader->load($module)) {
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

Dancer::Serializer::Mutable - Serialize and deserialize content using the appropriate HTTP header

=head1 SYNOPSIS

    # in config.yml
    serializer: Mutable

    # in the app
    put '/something' => sub {
        # deserialized from request
        my $name = param( 'name' );
        
        ...

        # will be serialized to the most 
        # fitting format
        return { message => "user $name added" };
    };

=head1 DESCRIPTION

This serializer will try find the best (de)serializer for a given request.
For this, it will pick the first content type found from the following list
and use its related serializer.

=over

=item

The B<content_type> from the request headers

=item

the B<content_type> parameter from the URL

=item

the B<accept> from the request headers

=item

The default is B<application/json>

=back

The content-type/serializer mapping that C<Dancer::Serializer::Mutable>
uses is

    serializer               | content types
    ----------------------------------------------------------
    Dancer::Serializer::YAML | text/x-yaml, text/html
    Dancer::Serializer::XML  | text/xml
    Dancer::Serializer::JSON | text/x-json, application/json

=head1 EXPORTABLE FUNCTIONS

=head2 template_or_serialize( $template, $data, $options )

For instances where you want to render a template for normal browser requests,
and return serialized content for AJAX calls. 

If the requested content-type is I<text/html>, C<template_or_serialize>
returns the rendered template, else it returns I<$data> unmodified 
(which will then be serialized as usual).

C<template_or_serialize> is not exported by default.

    use Dancer::Serializer::Mutable qw/ template_or_serialize /;

    get '/greetings' => sub {
        ...;

        return template_or_serialize 'greetings' => {
            title => $title,
            name  => $name,
        };
    };

=head2 INTERNAL METHODS

The following methods are used internally by C<Dancer> and are not made
accessible via the DSL.

=head2 serialize

Serialize a data structure. The format it is serialized to is determined
automatically as described above. It can be one of YAML, XML, JSON, defaulting
to JSON if there's no clear preference from the request.

=head2 deserialize

Deserialize the provided serialized data to a data structure.  The type of 
serialization format depends on the request's content-type. For now, it can 
be one of YAML, XML, JSON.

=head2 content_type

Returns the content-type that was used during the last C<serialize> /
C<deserialize> call. B<WARNING> : you must call C<serialize> / C<deserialize>
before calling C<content_type>. Otherwise the return value will be C<undef>.
