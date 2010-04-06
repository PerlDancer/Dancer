package Dancer::Timer;

use strict;
use warnings;
use base 'Dancer::Object';
use Time::HiRes 'gettimeofday', 'tv_interval';

use Dancer::ModuleLoader;
Dancer::Timer->attributes('start_time');

sub init { 
    my ($self) = @_;
    $self->start_time([ gettimeofday() ]);
}

sub tick { 
    my ($self) = @_;
    my $now = [ gettimeofday() ];
    my $delay = tv_interval($self->start_time, $now);
    return sprintf('%0f', $delay);
}

sub to_string {
    my ($self) = @_;
    $self->tick;
}

1;
