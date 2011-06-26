package Dancer::Hook::Properties;
# ABSTRACT: Properties attached to a hook
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

=method should_run_this_app

Auxiliary method for Hooks system that verifies if a hook should be
run for a specific application (passed as argument).

=cut
sub should_run_this_app {
    my ( $self, $app ) = @_;

    return 1 unless scalar( @{ $self->apps } );

    if ( $self->apps ) {
        return grep { $_ eq $app } @{ $self->apps };
    }
}

1;
__END__

=head1 CORE LIBRARY

This class is part of the core, it is provided for developers only.
Dancer users should not need to read this documentation as it
documents internal parts of the code only.

=head1 DESCRIPTION

Properties attached to a hook

=cut
