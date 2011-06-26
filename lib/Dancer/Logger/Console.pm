package Dancer::Logger::Console;
# ABSTRACT: console-based logging engine for Dancer
use strict;
use warnings;
use base 'Dancer::Logger::Abstract';

=method _log

Writes the log message to the console/screen.

=cut
sub _log {
    my ($self, $level, $message) = @_;
    print STDERR $self->format_message($level => $message);
}

1;

__END__

=head1 DESCRIPTION

This is a console-based logging engine that prints your logs to the console.

=cut
