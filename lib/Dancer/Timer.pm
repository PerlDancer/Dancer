package Dancer::Timer;
# ABSTRACT: timer for dancer logger engines

=head1 SYNOPSIS

    use Dancer::Timer;

    my $timer = Dancer::Timer->new();
    my $time  = $timer->tick;
    print "[$time]: Doing something\n";

    # (time passes)
    $time = $timer->tick
    print "[$time]: Doing something else\n";

    # (time passes)
    $time = $timer->to_string;
    print "[$time]: Doing another thing\n";

=head1 DESCRIPTION

Dancer::Timer provides Dancer with a timing object to clock operations. For
example, you might want a logging that shows you when each operation happened
(at what time) to determine how long each operation was in order to know where
to focus on for possible bugs or perhaps unnecessary slowness.

Dancer uses Dancer::Timer in facilities that want to provide this for you. Any
plugin author is more than welcome to use it as well.

=cut

use strict;
use warnings;
use base 'Dancer::Object';
use Time::HiRes 'gettimeofday', 'tv_interval';

use Dancer::ModuleLoader;

=attr start_time

Retains the starting time of the timer. The default value is when the object is
created. It fetches that using C<gettimeofday> from L<Time::HiRes>.

=cut
Dancer::Timer->attributes('start_time');

=method init

This method is called when C<< ->new() >> is called. It initializes the
C<start_time> attribute.

=cut
sub init {
    my ($self) = @_;
    $self->start_time([gettimeofday()]);
}

=method tick

Creates a tick in the timer and returns the interval between the C<start_time>
and now.

=cut
sub tick {
    my ($self) = @_;
    my $now = [gettimeofday()];
    my $delay = tv_interval($self->start_time, $now);
    return sprintf('%0f', $delay);
}

=method to_string

Same as C<tick>, just more expressive.

=cut
sub to_string {
    my ($self) = @_;
    $self->tick;
}

1;

__END__




