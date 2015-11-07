package Dancer::Hook::Properties;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: Properties attached to a hook
$Dancer::Hook::Properties::VERSION = '1.3202';
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Hook::Properties - Properties attached to a hook

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

=head1 DESCRIPTION

Properties attached to a hook

=head1 METHODS

=head1 AUTHORS

This module has been written by Alexis Sukrieh and others.

=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
