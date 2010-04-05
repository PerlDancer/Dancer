package Dancer::Timer;

use strict;
use warnings;
use base 'Dancer::Object';

use Dancer::ModuleLoader;
Dancer::Timer->attributes('mode');

my $_start_time = undef;
sub start_time { $_start_time }

sub init { 
    my ($self) = @_;
    if (Dancer::ModuleLoader->load('Time::HiRes')) {
        $self->mode('hires');
        $_start_time = [ Time::HiRes::gettimeofday() ]
    }
    else {
        $self->mode('seconds');
        $_start_time = time();
    }
}

sub tick { 
    my ($self) = @_;
    if ($self->mode eq 'hires') {
        my $now = [ Time::HiRes::gettimeofday() ];
        return Time::HiRes::tv_interval($_start_time, $now);
    }
    else {
        my $now = time();
        return $now - $_start_time;
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
