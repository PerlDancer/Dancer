package Dancer::Timer;

use strict;
use warnings;
use base 'Dancer::Object';

use Dancer::ModuleLoader;
Dancer::Timer->attributes('mode', 'start_time');

sub init { 
    my ($self) = @_;
    if (Dancer::ModuleLoader->load('Time::HiRes')) {
        $self->mode('hires');
        $self->start_time([ Time::HiRes::gettimeofday() ]);
    }
    else {
        $self->mode('seconds');
        $self->start_time(time());
    }
}

sub tick { 
    my ($self) = @_;
    if ($self->mode eq 'hires') {
        my $now = [ Time::HiRes::gettimeofday() ];
        my $delay = Time::HiRes::tv_interval($self->start_time, $now);
        return sprintf('%0f', $delay);
    }
    else {
        my $now = time();
        return $now - $self->start_time;
    }
}

sub to_string {
    my ($self) = @_;
    if ($self->mode eq 'hires') {
        $self->tick;
    }
    else {
        localtime(time());
    }
}

1;
