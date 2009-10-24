package Dancer::Cookie;
use strict;
use warnings;

use base 'Dancer::Object';
__PACKAGE__->attributes(
    'name', 
    'value',
    'expires',
    'domain',
    'path'
);

sub init {
    my $self = shift;
    if ($self->expires) {
        $self->expires(_epoch_to_gmtstring($self->expires))
            if $self->expires =~ /^\d+$/;
    }
    $self->path('/') unless defined $self->path;
}

sub to_header {
    my $self = shift;
    my $header = '';
    $header .= $self->name.'='.$self->value.'; ';
    $header .= "path=".$self->path."; " if $self->path;
    $header .= "expires=".$self->expires."; " if $self->expires;
    $header .= "domain=".$self->domain."; " if $self->domain;
    $header .= 'HttpOnly';
}

sub _epoch_to_gmtstring {
    my ($epoch) = @_;
    
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($epoch);
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @days   = qw(- Mon Tue Wed Thu Fri Sat Sun);

    return $days[$wday].", "
         . $mday."-".$months[$mon]
         . "-".($year + 1900)
         . " ${hour}:${min}:${sec} GMT";
}

1;
