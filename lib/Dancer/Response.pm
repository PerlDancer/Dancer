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

my @headers = qw(status content_type);
declare_accessor($_) for @headers;

sub declare_accessor {
    my ($name) = @_;

    my $code = sub {
        my ($value) = @_;
        $CURRENT->{$name} = $value;
    };

    my $accessor = "Dancer::Response::$name";
    {
        no strict 'refs';
        no warnings;
        *$accessor = $code;
    }
}

'Dancer::Response';
