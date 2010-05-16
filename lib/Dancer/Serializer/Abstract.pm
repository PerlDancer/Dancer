package Dancer::Serializer::Abstract;

use strict;
use warnings;
use base 'Dancer::Engine';

sub serialize   { die 'must be implemented' }
sub deserialize { die 'must be implemented' }

# must be implemented to delcare if the serializer can be used or not
# most of the time, just use :
# Dancer::ModuleLoader->load('Your::Serializer::Deps');
sub loaded { 0 }

# should be implemented, fallback to text/plain if not
sub content_type { 'text/plain' }

# most serializer don't have to overload this one
sub support_content_type {
    my ($self, $ct) = @_;
    return $ct eq $self->content_type;
}

1;
