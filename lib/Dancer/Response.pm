package Dancer::Response;

use strict;
use warnings;
use Carp 'confess';

use Dancer::HTTP;

# a singleton to store current response being built
my $CURRENT = {};

# the accessor returns a copy of the singleton after having purged it.
sub current { 
    my $cp = $CURRENT; 
    $CURRENT = {}; 
    return $cp; 
}

sub assert_route_context {
# FIXME : we have to find the way to detect that correctly
    return 1;
    my ($caller) = caller(0);
    if ($caller !~ /^Dancer::/) {
        confess "Cannot call this method outside a route handler ($caller), maybe you want to set someting?";
    }
}

sub set          { $CURRENT = shift }
sub status       { assert_route_context and $CURRENT->{status} = shift }
sub content_type { assert_route_context and $CURRENT->{content_type} = shift }
sub pass         { assert_route_context $CURRENT->{pass} = 1 }

'Dancer::Response';
