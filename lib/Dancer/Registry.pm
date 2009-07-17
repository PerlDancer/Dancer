package Dancer::Registry;

use strict;
use warnings;

# singleton for stroing the routes defined
my $REG = {};

# accessor for setting up a new route
sub add_route {
    my ($class, $method, $route, $code) = @_;
    $REG->{routes}{$method} ||= [];
    push @{ $REG->{routes}{$method} }, {route => $route, code => $code};
}

# return the first route that matches the path
sub find_route {
    my ($class, $path, $method) = @_;
    $method ||= 'get';
    
    foreach my $r (@{$REG->{routes}{$method}}) {
        my $params = route_match($path, $r->{route});
        if ($params) {
            $r->{params} = $params;
            return $r;
        }
    }
    return undef;
}

sub call_route {
    my ($class, $route) = @_;
    my $code = $route->{code};
    my $params = $route->{params};
    ref($params) eq 'HASH'
        ? $code->(%$params)
        : $code->() ;
}

sub route_match {
    my ($path, $route) = @_;
    my ($regexp, @variables) = make_regexp_from_route($route);

    if (@variables) {
        my @values = $path =~ $regexp;
        return 0 unless @values;
        my %params;
        for (my $i=0; $i< ~~@variables; $i++) {
            $params{$variables[$i]} = $values[$i];
        }
        return \%params;
    }
    else {
        return $path =~ $regexp;
    }
}

# replace any ':foo' by '(.+)' and stores all the named 
# matches defined in $REG->{route_params}{$route}
sub make_regexp_from_route {
    my ($route) = @_;
    my $pattern = $route;
    my @params = $pattern =~ /:([^\/]+)/g;
    if (@params) {
        $REG->{route_params}{$route} = \@params;
        $pattern =~ s/(:[^\/]+)/\(\.\+\)/g;
    }
    $pattern =~ s/\//\\\//g;
    return '^'.$pattern.'$', @params;
}

'Dancer::Registry';
