package Dancer::Logger::Console;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: console-based logging engine for Dancer
$Dancer::Logger::Console::VERSION = '1.3202';
use strict;
use warnings;
use base 'Dancer::Logger::Abstract';

sub _log {
    my ($self, $level, $message) = @_;
    print STDERR $self->format_message($level => $message);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Logger::Console - console-based logging engine for Dancer

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a console-based logging engine that prints your logs to the console.

=head1 METHODS

=head2 _log

Writes the log message to the console/screen.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
