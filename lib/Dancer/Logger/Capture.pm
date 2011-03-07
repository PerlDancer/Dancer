package Dancer::Logger::Capture;

use strict;
use warnings;


=head1 NAME

Dancer::Logger::Capture - Capture dancer logs

=head1 SYNOPSIS

    set logger => "capture";

    my $trap = Dancer::Logger::Capture->trap;
    my $logs = $trap->read;

=head1 DESCRIPTION

This is a logger class for L<Dancer> which captures all logs to an object.

It's primary purpose is for testing.

=head2 Methods

=head3 trap

Returns the L<Dancer::Logger::Capture::Trap> object used to capture
and read logs.

=cut

use base "Dancer::Logger::Abstract";

use Dancer::Logger::Capture::Trap;
my $Trap = Dancer::Logger::Capture::Trap->new;

sub _log {
    my($self, $level, $message) = @_;

    $Trap->store( $level => $message );
    return;
}

sub trap {
    return $Trap;
}


=head1 SEE ALSO

L<Dancer::Logger>, L<Dancer::Logger::Capture::Trap>

=cut

1;
