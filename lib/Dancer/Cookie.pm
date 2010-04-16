package Dancer::Cookie;
use strict;
use warnings;

use base 'Dancer::Object';
__PACKAGE__->attributes('name', 'value', 'expires', 'domain', 'path');

sub init {
    my $self = shift;
    if ($self->expires) {
        $self->expires(_epoch_to_gmtstring($self->expires))
          if $self->expires =~ /^\d+$/;
    }
    $self->path('/') unless defined $self->path;
}

sub to_header {
    my $self   = shift;
    my $header = '';
    $header .= $self->name . '=' . $self->value . '; ';
    $header .= "path=" . $self->path . "; " if $self->path;
    $header .= "expires=" . $self->expires . "; " if $self->expires;
    $header .= "domain=" . $self->domain . "; " if $self->domain;
    $header .= 'HttpOnly';
}

sub _epoch_to_gmtstring {
    my ($epoch) = @_;

    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($epoch);
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @days   = qw(- Mon Tue Wed Thu Fri Sat Sun);

    return sprintf "%s, %02d-%s-%d %02d:%02d:%02d GMT",
        $days[$wday],
        $mday,
        $months[$mon],
        ($year + 1900),
        $hour, $min, $sec;
}

1;

__END__

=pod

=head1 NAME

Dancer::Cookie - A Dancer cookie object

=head1 SYNOPSIS

    use Dancer::Cookie;

    my $cookie = Dancer::Cookie->new(
        name => $cookie_name, value => $cookie_value
    );

=head1 DESCRIPTION

Dancer::Cookie provides a HTTP cookie object to work with cookies.

=head1 ATTRIBUTES

=head3 name

The cookie's name.

=head3 value

The cookie's value.

=head2 expires

The cookie's expiration date.

=head2 domain

The cookie's domain.

=head2 path

The cookie's path.

=head1 METHODS/SUBROUTINES

=head2 new

Create a new Dancer::Cookie object.

You can set any attribute described in the I<ATTRIBUTES> section above.

=head2 init

Runs an expiration test and sets a default path if not set.

=head2 to_header

Creates a proper HTTP cookie header from the content.

=head2 _epoch_to_gmtstring

Internal method to convert the time from Epoch to GMT.

=head1 AUTHOR

Alexis Sukrieh

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2010 Alexis Sukrieh.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

