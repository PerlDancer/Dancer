package Dancer::Logger::Diag;
use strict;
use warnings;
use base 'Dancer::Logger::Abstract';

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    require Test::More;
}

sub _log {
    my ($self, $level, $message) = @_;

    Test::More::diag(
        $self->format_message( $level => $message )
    );
}

1;

__END__

=head1 NAME

Dancer::Logger::Diag - Test::More diag() logging engine for Dancer

=head1 SYNOPSIS

=head1 DESCRIPTION

This logging engine uses L<Test::More>'s diag() to output as TAP comments.

This is very useful in case you're writing a test and want to have logging
messages as part of your TAP.

=head1 METHODS

=head2 init

This method is called when C<< ->new() >> is called. It just loads Test::More
lazily.

=head2 _log

Use Test::More's diag() to output the log message.

=head1 AUTHOR

Alexis Sukrieh

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2010 Alexis Sukrieh.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

