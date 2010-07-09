package Dancer::App;

use strict;
use warnings;
use base 'Dancer::Object';

use Dancer::Route::Registry;

Dancer::App->attributes(qw(name registry settings));

# singleton that saves any app created, we want unicity for app names
my $_apps = {};
sub applications { values %$_apps }

sub set_running_app {
    my ($self, $name) = @_;
    my $app = Dancer::App->get($name);
    $app = Dancer::App->new(name => $name) unless defined $app;
    Dancer::App->current($app);
}

sub init {
    my ($self) = @_;
    $self->name('main') unless defined $self->name;

    die "an app named '".$self->name."' already exists" 
        if exists $_apps->{ $self->name };
    
    # default values for properties
    $self->settings({});
    $self->init_registry();

    $_apps->{ $self->name } = $self;
}

sub init_registry {
    my ($self, $reg) = @_;
    $self->registry($reg || Dancer::Route::Registry->new);
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
