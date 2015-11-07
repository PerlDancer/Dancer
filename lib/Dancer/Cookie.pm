package Dancer::Cookie;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: class representing cookies
$Dancer::Cookie::VERSION = '1.3202';
use strict;
use warnings;

use URI::Escape;

use base 'Dancer::Object';
__PACKAGE__->attributes( qw/name expires domain path secure http_only/ );

sub init {
    my ($self, %args) = @_;
    $self->value($args{value});
    if (my $time = $self->expires) {
        # First, normalize things like +2h to # of seconds
        $time = _parse_duration($time) if $time !~ /^\d+$/;

        # Then translate to a gmt string, if it isn't one already
        $time = _epoch_to_gmtstring($time) if $time =~ /^\d+$/;

        $self->expires($time);
    }
    $self->path('/') unless defined $self->path;
}

sub to_header {
    my $self   = shift;
    my $header = '';

    my $value       = join('&', map {uri_escape($_)} $self->value);
    my $no_httponly = defined( $self->http_only ) && $self->http_only == 0;

    my $name = $self->name;
    $name =~ s/[=,; \t\r\n\013\014]//mg;

    my @headers = $name . '=' . $value;
    push @headers, "path=" . $self->path        if $self->path;
    push @headers, "expires=" . $self->expires  if $self->expires;
    push @headers, "domain=" . $self->domain    if $self->domain;
    push @headers, "Secure"                     if $self->secure;
    push @headers, 'HttpOnly'                   unless $no_httponly;

    return join '; ', @headers;
}

sub value {
    my ( $self, $value ) = @_;
    if ( defined $value ) {
        my @values =
            ref $value eq 'ARRAY' ? @$value
          : ref $value eq 'HASH'  ? %$value
          :                         ($value);
        $self->{'value'} = [@values];
    }
    return wantarray ? @{ $self->{'value'} } : $self->{'value'}->[0];
}

sub _epoch_to_gmtstring {
    my ($epoch) = @_;

    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($epoch);
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @days   = qw(Sun Mon Tue Wed Thu Fri Sat);

    return sprintf "%s, %02d-%s-%d %02d:%02d:%02d GMT",
      $days[$wday],
      $mday,
      $months[$mon],
      ($year + 1900),
      $hour, $min, $sec;
}

# This map is taken from Cache and Cache::Cache
# map of expiration formats to their respective time in seconds
my %Units = ( map(($_,             1), qw(s second seconds sec secs)),
              map(($_,            60), qw(m minute minutes min mins)),
              map(($_,         60*60), qw(h hr hour hours)),
              map(($_,      60*60*24), qw(d day days)),
              map(($_,    60*60*24*7), qw(w week weeks)),
              map(($_,   60*60*24*30), qw(M month months)),
              map(($_,  60*60*24*365), qw(y year years)) );

# This code is taken from Time::Duration::Parse, except if it isn't
# understood it just passes it through and it adds the current time.
sub _parse_duration {
    my $timespec = shift;
    my $orig_timespec = $timespec;

    # Treat a plain number as a number of seconds (and parse it later)
    if ($timespec =~ /^\s*([-+]?\d+(?:[.,]\d+)?)\s*$/) {
        $timespec = "$1s";
    }

    # Convert hh:mm(:ss)? to something we understand
    $timespec =~ s/\b(\d+):(\d\d):(\d\d)\b/$1h $2m $3s/g;
    $timespec =~ s/\b(\d+):(\d\d)\b/$1h $2m/g;

    my $duration = 0;
    while ($timespec =~ s/^\s*([-+]?\d+(?:[.,]\d+)?)\s*([a-zA-Z]+)(?:\s*(?:,|and)\s*)*//i) {
        my($amount, $unit) = ($1, $2);
        $unit = lc($unit) unless length($unit) == 1;

        if (my $value = $Units{$unit}) {
            $amount =~ s/,/./;
            $duration += $amount * $value;
        } else {
            return $orig_timespec;
        }
    }

    if ($timespec =~ /\S/) {
        return $orig_timespec;
    }

    return sprintf "%.0f", $duration + time;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Cookie - class representing cookies

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

    use Dancer::Cookie;

    my $cookie = Dancer::Cookie->new(
        name => $cookie_name, value => $cookie_value
    );

=head1 DESCRIPTION

Dancer::Cookie provides an HTTP cookie object to work with cookies.

=head1 ATTRIBUTES

=head2 name

The cookie's name.

=head2 value

The cookie's value.

=head2 expires

The cookie's expiration date.  There are several formats.

Unix epoch time like 1288817656 to mean "Wed, 03-Nov-2010 20:54:16 GMT"

A human-readable offset from the current time such as "2 hours".  It currently
understands...

    s second seconds sec secs
    m minute minutes min mins
    h hr hour hours
    d day days
    w week weeks
    M month months
    y year years

Months and years are currently fixed at 30 and 365 days.  This may change.

Anything else is used verbatim.

=head2 domain

The cookie's domain.

=head2 path

The cookie's path.

=head2 secure

If true, it instructs the client to only serve the cookie over secure
connections such as HTTPS.

=head2 http_only

By default cookies are created with a property named C<HttpOnly>,
that can be used for security, forcing the cookie to be used only by
the server (via HTTP) and not by any JavaScript code.

If your cookie is meant to be used by some JavaScript code, set this
attribute to 0.

=head1 METHODS/SUBROUTINES

=head2 new

Create a new Dancer::Cookie object.

You can set any attribute described in the I<ATTRIBUTES> section above.

=head2 init

Runs an expiration test and sets a default path if not set.

=head2 to_header

Creates a proper HTTP cookie header from the content.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
