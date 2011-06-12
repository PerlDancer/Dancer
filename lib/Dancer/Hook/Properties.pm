package Dancer::Hook::Properties;
# ABSTRACT: Properties attached to a hook

=head1 DESCRIPTION

Properties attached to a hook

=head1 SYNOPSIS

=cut
use strict;
use warnings;

use base 'Dancer::Object';

Dancer::Hook::Properties->attributes(qw/apps/);

sub init {
    my ($self, %args) = @_;

    $self->_init_apps(\%args);
    return $self;
}

sub _init_apps {
    my ( $self, $args ) = @_;
    if ( my $apps = $args->{'apps'} ) {
        ref $apps ? $self->apps($apps) : $self->apps( [$apps] );
        return;
    }
    else {
        $self->apps( [] );
    }
}

sub should_run_this_app {
    my ( $self, $app ) = @_;

    return 1 unless scalar( @{ $self->apps } );

    if ( $self->apps ) {
        return grep { $_ eq $app } @{ $self->apps };
    }
}

1;
