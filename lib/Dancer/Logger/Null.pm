package Dancer::Logger::Null;
use strict;
use warnings;
use base 'Dancer::Logger::Abstract';

sub _log {1}

1;

__END__

=head1 NAME

Dancer::Logger::Null - blackhole-like silent logging engine for Dancer

=head1 SYNOPSIS

=head1 DESCRIPTION

This logger acts as a blackhole (or /dev/null, if you will) that discards all
the log messages instead of displaying them anywhere.

=head1 METHODS

=head2 _log

Discards the message.

=head1 AUTHOR

Alexis Sukrieh

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2010 Alexis Sukrieh.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

