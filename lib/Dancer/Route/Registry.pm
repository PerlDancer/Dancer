package Dancer::Route::Registry;
# ABSTRACT: class representing a registry for storing route objects

use strict;
use warnings;
use Carp;
use Dancer::Route;
use base 'Dancer::Object';
use Dancer::Logger;

Dancer::Route::Registry->attributes(qw( id ));

my $id = 1;

=method init

Initializes the object.

=cut
sub init {
    my ($self) = @_;

    unless (defined $self->{id}) {
        $self->id($id++);
    }
    $self->{routes} = {};

    return $self;
}

=method is_empty

Returns a boolean telling if the registry is empty or not (being empty
means it has no routes registered).

=cut
sub is_empty {
    my ($self) = @_;
    for my $method ( keys %{ $self->routes } ) {
        return 0 if $self->routes($method);
    }
    return 1;
}

=method routes

Return all the route objects stored in the registry.

=cut
sub routes {
    my ($self, $method) = @_;

    if ($method) {
        my $route = $self->{routes}{$method};
        return $route ? $route : [];
    }
    else {
        return $self->{routes};
    }
}

=method add_route

Register a route in the registry

=cut
sub add_route {
    my ($self, $route) = @_;
    $self->{routes}{$route->method} ||= [];
    my @registered = @{$self->routes($route->method)};
    my $last       = $registered[-1];
    $route->set_previous($last) if defined $last;

    # if the route have options, we store the route at the begining
    # of the routes. This way, we can have the following routes:
    # get '/' => sub {} and ajax '/' => sub {}
    # and the user won't have to declare the ajax route before the get
    if (keys %{$route->{options}}) {
        unshift @{$self->routes($route->method)}, $route;
    }
    else {
        push @{$self->routes($route->method)}, $route;
    }
    return $route;
}

=method any_add

Sugar for Dancer.pm

      class, any, ARRAY(0x9864818), '/path', CODE(0x990ac88)

or
      class, any, '/path', CODE(0x990ac88)

Used to register one C<any> route.

=cut
sub any_add {
    my ($self, $pattern, @rest) = @_;

    my @methods = qw(get post put delete options);

    if (ref($pattern) eq 'ARRAY') {
        @methods = @$pattern;
        $pattern = shift @rest;
    }

    croak "Syntax error, methods should be provided as an ARRAY ref"
      if grep {$_ eq $pattern} @methods;

    $self->universal_add($_, $pattern, @rest) for @methods;
    return scalar(@methods);
}

=method universal_add

Registers a route.

=cut
sub universal_add {
    my ($self, $method, $pattern, @rest) = @_;

    my %options;
    my $code;

    if (@rest == 1) {
        $code = $rest[0];
    }
    else {
        %options = %{$rest[0]};
        $code    = $rest[1];
    }

    my %route_args = (
        method  => $method,
        code    => $code,
        options => \%options,
        pattern => $pattern,
    );

    return $self->_register_route(%route_args);
}

# private


# look for a route in the given array
sub _NOT_USED_ANYWHERE_find_route {
    my ($self, $r, $reg) = @_;
    foreach my $route (@$reg) {
        return $route if $r->equals($route);
    }
    return;
}

# sugar for add_route

sub _register_route {
    my ($self, %args) = @_;

    # look if the caller (where the route is declared) exists as a Dancer::App
    # object
    my ($package) = caller(2);
    if ($package && Dancer::App->app_exists($package)) {
        my $app = Dancer::App->get($package);
        my $route = Dancer::Route->new(prefix => $app->prefix, %args);
        return $app->registry->add_route($route);
    }
    else {

        # FIXME maybe this code is useless, drop it later if so
        my $route = Dancer::Route->new(%args);
        return $self->add_route($route);
    }
}


1;
