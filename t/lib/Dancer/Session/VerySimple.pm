package Dancer::Session::VerySimple;

use strict;
use warnings;
use base 'Dancer::Session::Abstract';

my %sessions;

# create a new session and return the newborn object
# representing that session
sub create {
    my ($class) = @_;

    my $self = Dancer::Session::VerySimple->new;
    $self->flush;
    return $self;
}

sub destroy {
    my ($self) = @_;
    undef $sessions{$self->id};
}

sub flush {
    my $self = shift;
    $sessions{$self->id} = $self;
    return $self;
}

# Return the session object corresponding to the given id
sub retrieve {
    my ($class, $id) = @_;

    $::retrieve++;

    return $sessions{$id};
}



1;
