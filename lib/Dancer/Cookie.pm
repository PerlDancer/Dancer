package Dancer::Cookie;
use strict;
use warnings;

sub new {
    my ($class, %attrs) = @_;
    my $self = {
        name => undef,
        value => undef,
        attributes => {
            expires => undef,
            path => '/',
            domain => undef,
        },
        %attrs,
    };
    bless $self, $class;
    $self->init();

    return $self;
}

sub init {
    my $self = shift;
    if ($self->expires) {
        $self->expires(epoch_to_gmtstring($self->expires))
            if $self->expires =~ /^\d+$/;
    }
}

sub expires { 
    my ($self, $value) = @_;
    if (@_ == 1) {
        return $self->{attributes}{expires};
    }
    else {
        return $self->{attributes}{expires} = $value;
    }
}

sub epoch_to_gmtstring {
    my ($epoch) = @_;
    
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($epoch);
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @days   = qw(- Mon Tue Wed Thu Fri Sat Sun);

    return $days[$wday].", "
         . $mday."-".$months[$mon]
         . "-".($year + 1900)
         . " ${hour}:${min}:${sec} GMT";
}

sub attributes { 
    my $self = shift;
    map { 
        defined($self->{attributes}{$_}) ? ($_."=".$self->{attributes}{$_}) : ()
    } keys %{$self->{attributes}}; 
}

sub to_header {
    my $self = shift;
    return $self->{name} . '=' . $self->{value} . '; '
      . join("; ", $self->attributes);
}

1;
