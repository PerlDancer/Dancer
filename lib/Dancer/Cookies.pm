package Dancer::Cookies;
use strict;
use warnings;

use Dancer::Cookie;
use Dancer::SharedData;

use URI::Escape;

# all cookies defined by the application are store in that singleton
# this is a hashref the represent all key/value pairs to store as cookies
my $COOKIES = {};
sub cookies {$COOKIES}

sub init {
    $COOKIES = parse_cookie_from_env();
}

sub parse_cookie_from_env {
    my $request = Dancer::SharedData->request;
    my $env     = (defined $request) ? $request->env : {};
    my $env_str = $env->{COOKIE} || $env->{HTTP_COOKIE};
    return {} unless defined $env_str;

    my $cookies = {};
    foreach my $cookie ( split( /[,;]\s/, $env_str ) ) {
        my ( $name, $value ) = split( '=', $cookie );
        my @values;
        if ( $value ne '' ) {
            @values = map { uri_unescape($_) } split( /[&;]/, $value );
        }
        $cookies->{$name} =
          Dancer::Cookie->new( name => $name, value => \@values );
    }

    return $cookies;
}

# set_cookie name => value,
#     expires => time() + 3600, domain => '.foo.com'
#     http_only => 0 # defaults to 1
sub set_cookie {
    my ( $class, $name, $value, %options ) = @_;
    my $cookie =  Dancer::Cookie->new(
        name  => $name,
        value => $value,
        %options
    );
    Dancer::Cookies->set_cookie_object($name => $cookie);
}

sub set_cookie_object {
    my ($class, $name, $cookie) = @_;
    Dancer::SharedData->response->push_header(
        'Set-Cookie' => $cookie->to_header);
    Dancer::Cookies->cookies->{$name} = $cookie;
}

1;

__END__

=head1 NAME

Dancer::Cookies - a singleton storage for all cookies

=head1 SYNOPSIS

    use Dancer::Cookies;

    my $cookies = Dancer::Cookies->cookies;

    foreach my $name ( keys %{$cookies} ) {
        my $cookie = $cookies->{$name};
        my $value  = $cookie->value;
        print "$name => $value\n";
    }

=head1 DESCRIPTION

Dancer::Cookies keeps all the cookies defined by the application and makes them
accessible and provides a few helper functions for cookie handling with regards
to the stored cookies.

=head1 METHODS

=head2 init

This method is called when C<< ->new() >> is called. It creates a storage of
cookies parsed from the environment using C<parse_cookies_from_env> described
below.

=head2 cookies

Returns a hash reference of all cookies, all objects of L<Dancer::Cookie> type.

The key is the cookie name, the value is the L<Dancer::Cookie> object.

=head2 parse_cookie_from_env

Fetches all the cookies from the environment, parses them and creates a hashref
of all cookies.

It also returns all the hashref it created.

=head1 AUTHOR

Alexis Sukrieh

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2010 Alexis Sukrieh.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

