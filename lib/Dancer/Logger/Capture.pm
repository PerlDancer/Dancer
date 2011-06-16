package Dancer::Logger::Capture;
# ABSTRACT: Capture dancer logs

=head1 SYNOPSIS

    set logger => "capture";

    my $trap = Dancer::Logger::Capture->trap;
    my $logs = $trap->read;

=head1 DESCRIPTION

This is a logger class for L<Dancer> which captures all logs to an object.

It's primary purpose is for testing.

=cut

use strict;
use warnings;

use base "Dancer::Logger::Abstract";

use Dancer::Logger::Capture::Trap;
my $Trap = Dancer::Logger::Capture::Trap->new;

=method trap

Returns the L<Dancer::Logger::Capture::Trap> object used to capture
and read logs.

=cut

sub trap {
    return $Trap;
}

# private

sub _log {
    my($self, $level, $message) = @_;

    $Trap->store( $level => $message );
    return;
}


1;

__END__

=head1 EXAMPLE

    use Test::More import => ['!pass'], tests => 2;
    use Dancer;

    set logger => 'capture';

    warning "Danger!  Warning!";
    debug   "I like pie.";

    my $trap = Dancer::Logger::Capture->trap;
    is_deeply $trap->read, [
        { level => "warning", message => "Danger!  Warning!" },
        { level => "debug",   message => "I like pie.", }
    ];

    # each call to read cleans the trap
    is_deeply $trap->read, [];

=cut
