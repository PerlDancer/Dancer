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

sub set          { $CURRENT = shift }
sub status       { $CURRENT->{status} = shift }
sub content_type { $CURRENT->{content_type} = shift }
sub pass         { $CURRENT->{pass} = 1 }

'Dancer::Response';
