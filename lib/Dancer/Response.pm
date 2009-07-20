package Dancer::Response;

use strict;
use warnings;

use Dancer::HTTP;

# a singleton to store current response being built
my $CURRENT = {};

# the accessor returns a copy of the singleton after having purged it.
sub current { 
    my $cp = $CURRENT; 
    $CURRENT = {}; 
    return $cp; 
}

# TODO We should refactor that on something generic with closures...
sub status { 
    my ($value) = @_; 
    $CURRENT->{status} = $value;
}

sub content_type { 
    my ($value) = @_; 
    $CURRENT->{content_type} = $value;
}

'Dancer::Response';
