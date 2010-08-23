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

sub clone {
    my ($self) = @_;
    die "The 'Clone' module is needed"
      unless Dancer::ModuleLoader->load('Clone');
    return Clone::clone($self);
}

# initializer
sub init {1}

# meta information about classes
my $_attrs_per_class = {};
sub get_attributes { $_attrs_per_class->{$_[0]} }

# accessors builder
sub attributes {
    my ($class, @attributes) = @_;

    # save meta information
    $_attrs_per_class->{$class} = \@attributes;

    # define setters and getters for each attribute
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
