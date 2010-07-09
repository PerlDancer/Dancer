package Dancer::App;

use strict;
use warnings;
use base 'Dancer::Object';

Dancer::App->attributes(qw(name routes settings));

# singleton that saves any app created, we want unicity for app names
my $_apps = {};

sub init {
    my ($self) = @_;
    $self->name('main') unless defined $self->name;

    die "an app named '".$self->name."' already exists" 
        if exists $_apps->{ $self->name };

    $_apps->{ $self->name } = $self;
}

sub setting {
    my ($self, $name, $value) = @_;
    $self->settings({}) unless defined $self->settings;

    return (@_ == 3) 
        ? $self->settings->{$name} = $value
        : $self->settings;
}

1;
