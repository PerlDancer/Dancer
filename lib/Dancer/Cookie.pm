package Dancer::Cookie;
use strict;
use warnings;

sub new {
    my ($class, %attrs) = @_;
    my $self = {
        name => undef,
        value => undef,
        attributes => {
            expires => undef,
            path => '/',
            domain => undef,
        },
        %attrs,
    };
    bless $self, $class;
}

sub attributes { 
    my $self = shift;
    map { 
        defined($self->{attributes}{$_}) ? ($_."=".$self->{attributes}{$_}) : ()
    } keys %{$self->{attributes}}; 
}

sub to_header {
    my $self = shift;
    return $self->{name} . '=' . $self->{value} . '; '
      . join("; ", $self->attributes);
}

1;
