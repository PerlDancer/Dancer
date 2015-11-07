package Dancer::Timer;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: a timer for Dancer
$Dancer::Timer::VERSION = '1.3202';
use strict;
use warnings;
use base 'Dancer::Object';
use Time::HiRes 'gettimeofday', 'tv_interval';

use Dancer::ModuleLoader;
Dancer::Timer->attributes('start_time');

sub init {
    my ($self) = @_;
    $self->start_time([gettimeofday()]);
}

sub tick {
    my ($self) = @_;
    my $now = [gettimeofday()];
    my $delay = tv_interval($self->start_time, $now);
    return sprintf('%0f', $delay);
}

sub to_string {
    my ($self) = @_;
    $self->tick;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Timer - a timer for Dancer

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

    use Dancer::Timer;

    my $timer = Dancer::Timer->new();
    my $time  = $timer->tick;
    print "[$time]: Doing something\n";

    # (time passes)
    $time = $timer->tick;
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

=head1 ATTRIBUTES

=head2 start_time

Retains the starting time of the timer. The default value is when the object is
created. It fetches that using C<gettimeofday> from L<Time::HiRes>.

=head1 METHODS

=head2 init

This method is called when C<< ->new() >> is called. It initializes the
C<start_time> attribute.

=head2 tick

Creates a tick in the timer and returns the interval between the C<start_time>
and now.

=head2 to_string

Same as C<tick>, just more expressive.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
