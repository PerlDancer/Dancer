package Dancer::App;

use strict;
use warnings;
use base 'Dancer::Object';

use Dancer::Route::Registry;

Dancer::App->attributes(qw(name routes settings));

# singleton that saves any app created, we want unicity for app names
my $_apps = {};

sub init {
    my ($self) = @_;
    $self->name('main') unless defined $self->name;

    die "an app named '".$self->name."' already exists" 
        if exists $_apps->{ $self->name };
    
    # default values for properties
    $self->settings({});
    $self->routes(Dancer::Route::Registry->new);

    $_apps->{ $self->name } = $self;
}

# singleton that saves the current active Dancer::App object
my $_current;
sub current {
    my ($class, $app) = @_;
    return $_current = $app if defined $app;

    if (not defined $_current) {
        $_current = Dancer::App->get('main') || Dancer::App->new();
    }

    return $_current;
}

sub get {
    my ($class, $name) = @_;
    $_apps->{$name};
}

sub setting {
    my ($self, $name, $value) = @_;

    return (@_ == 3) 
        ? $self->settings->{$name} = $value
        : $self->settings->{$name};
}

1;
