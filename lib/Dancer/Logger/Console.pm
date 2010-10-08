package Dancer::Logger::Console;
use strict;
use warnings;
use base 'Dancer::Logger::Abstract';

sub _log {
    my ($self, $level, $message) = @_;
    print STDERR $self->format_message($level => $message);
}

1;

__END__

=head1 NAME

Dancer::Logger::Console - console-based logging engine for Dancer

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a console-based logging engine that prints your logs to the console.

=head1 METHODS

=head2 _log

Writes the log message to the console/screen.

=head1 AUTHOR

Alexis Sukrieh

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2010 Alexis Sukrieh.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

