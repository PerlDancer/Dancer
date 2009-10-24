package Dancer::Object;

# This class is a root class for each object in Dancer.
# It provides basic OO tools for Perl5 without being... Moose ;-)

use strict;
use warnings;

# constructor
sub new {
    my ($class, %args) = @_;
    my $self = \%args;
    bless $self, $class;
    $self->init(%args);
    return $self;
}

# initializer
sub init { 1 }

# accessors builder
sub attributes {
    my ($class, @attributes) = @_;

    foreach my $attr (@attributes) {
        my $code = sub { 
            my ($self, $value) = @_;
            if (@_ == 1) {
                return $self->{$attr};
            }
            else {
                return $self->{$attr} = $value;
            }
        }; 
        my $method = "${class}::${attr}";
        { no strict 'refs'; *$method = $code; }
    }
}

1;
