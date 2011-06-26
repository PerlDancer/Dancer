package Dancer::Logger::Null;
# ABSTRACT: blackhole-like silent logging engine for Dancer
use strict;
use warnings;
use base 'Dancer::Logger::Abstract';

=method _log

Discards the message.

=cut
sub _log {1}

1;

__END__

=head1 DESCRIPTION

This logger acts as a blackhole (or /dev/null, if you will) that discards all
the log messages instead of displaying them anywhere.

=cut

