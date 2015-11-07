package Dancer::Route::Registry;
our $AUTHORITY = 'cpan:SUKRIA';
# ABSTRACT: Route registry for Dancer
$Dancer::Route::Registry::VERSION = '1.3202';
use strict;
use warnings;
use Carp;
use Dancer::Route;
use base 'Dancer::Object';
use Dancer::Logger;
use Dancer::Exception qw(:all);

Dancer::Route::Registry->attributes(qw( id ));

my $id = 1;

sub init {
    my ($self) = @_;

    unless (defined $self->{id}) {
        $self->id($id++);
    }
    $self->{routes} = {};

    return $self;
}

sub is_empty {
    my ($self) = @_;
    for my $method ( keys %{ $self->routes } ) {
        return 0 if $self->routes($method);
    }
    return 1;
}

# replace any ':foo' by '(.+)' and stores all the named
# matches defined in $REG->{route_params}{$route}
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

sub add_route {
    my ($self, $route) = @_;
    $self->{routes}{$route->method} ||= [];
    my @registered = @{$self->routes($route->method)};
    my $last       = $registered[-1];
    $route->set_previous($last) if defined $last;

    # if the route have options, we store the route at the beginning
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

# sugar for add_route

sub register_route {
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

# sugar for Dancer.pm
# class, any, ARRAY(0x9864818), '/path', CODE(0x990ac88)
# or
# class, any, '/path', CODE(0x990ac88)
sub any_add {
    my ($self, $pattern, @rest) = @_;

    my @methods = qw(get post put patch delete options head);

    if (ref($pattern) eq 'ARRAY') {
        @methods = @$pattern;
        # 'get' defaults to 'get' and 'head'
        push @methods, 'head' if ((grep { $_ eq 'get' } @methods) and
                                 not (grep { $_ eq 'head' } @methods));
        $pattern = shift @rest;
    }

    raise core_route => "Syntax error, methods should be provided as an ARRAY ref"
      if grep {$_ eq $pattern} @methods;

    $self->universal_add($_, $pattern, @rest) for @methods;
    return scalar(@methods);
}

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

    return $self->register_route(%route_args);
}

# look for a route in the given array
sub find_route {
    my ($self, $r, $reg) = @_;
    foreach my $route (@$reg) {
        return $route if $r->equals($route);
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Route::Registry - Route registry for Dancer

=head1 VERSION

version 1.3202

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
