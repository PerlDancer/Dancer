package Dancer::Hook::Properties;

use strict;
use warnings;

use base 'Dancer::Object';

Dancer::Hook::Properties->attributes(qw/apps/);

sub init {
    my ($class, $self, @args) = @_;
    $self->apps([]);
    return $self;
}

sub should_run_this_app {
    my ( $self, $app ) = @_;

    return 1 unless scalar( @{ $self->apps } );

    if ( $self->apps ) {
        return grep { $_ eq $app->name } @{ $self->apps };
    }
}

1;
