package Dancer::Cookies;
use strict;
use warnings;

use Dancer::Cookie;
use Dancer::SharedData;

# all cookies defined by the application are store in that singleton
# this is a hashref the represent all key/value pairs to store as cookies
my $COOKIES = {};
sub cookies {$COOKIES}

sub parse_cookie_from_env {
    my $request = Dancer::SharedData->request;
    my $env     = (defined $request) ? $request->env : {};
    my $env_str = $env->{COOKIE} || $env->{HTTP_COOKIE};
    return {} unless defined $env_str;

    my $cookies = {};
    foreach my $cookie (split('; ', $env_str)) {
        my ($name, $value) = split('=', $cookie);
        $cookies->{$name} =
          Dancer::Cookie->new(name => $name, value => $value);
    }
    return $cookies;
}

sub init {
    $COOKIES = parse_cookie_from_env();
}

# return true if the given cookie is not the same as the one sent by the client
sub has_changed {
    my ($self, $cookie) = @_;
    my ($name, $value) = ($cookie->{name}, $cookie->{value});

    my $client_cookies = parse_cookie_from_env();
    my $search         = $client_cookies->{$name};
    return 1 unless defined $search;
    return $search->value ne $value;
}

1;
