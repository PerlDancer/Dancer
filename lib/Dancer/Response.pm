package Dancer::Response;

use strict;
use warnings;

use Dancer::Config 'setting';
use Dancer::HTTP;

# constructor
sub new {
    my ($class, %args) = @_;
    my $self = {
        status => 200,
        headers => {
            'Content-Type' => setting('content_type')},
        content => "",
        pass => 0,
        %args,
    };
    bless $self, $class;
    return $self;
}

# a singleton to store the current response
my $CURRENT = Dancer::Response->new();

# the accessor returns a copy of the singleton 
# after having purged it.
sub current { 
    my $cp = $CURRENT; 
    $CURRENT = Dancer::Response->new(); 
    return $cp; 
}

# helpers for the route handlers
sub set          { $CURRENT = shift }
sub status       { $CURRENT->{status} = shift }
sub content_type { $CURRENT->{content_type} = shift }
sub pass         { $CURRENT->{pass} = 1 }


'Dancer::Response';
