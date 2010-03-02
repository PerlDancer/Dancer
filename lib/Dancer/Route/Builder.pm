package Dancer::Route::Builder;
use strict;
use warnings;

my $_COMPILED_ROUTES = { _state => 'NEW' };

sub registry    { $_COMPILED_ROUTES }
sub is_new      { $_COMPILED_ROUTES->{_state} eq 'NEW' }
sub is_compiled { defined $_COMPILED_ROUTES->{$_[1]} }
sub get_regexp  { $_COMPILED_ROUTES->{$_[1]} }

sub compile {
    my ($class, $routes) = @_;
    foreach my $method (keys %$routes) {
        foreach my $route (@{$routes->{$method}}) {
            my ($regexp, @variables) = make_regexp($route);
            set_regexp($route => $regexp, \@variables);
        }
    }
    $_COMPILED_ROUTES->{_state} = 'DONE';
}

sub set_regexp {
    my ($route, $regexp, $params) = @_;

    my $key = $route->{'route'};
    $key = $key->{'regexp'} if ref($key);

    #warn "saving route for $key";
    $_COMPILED_ROUTES->{$key} = [ $regexp => $params ];
}


# replace any ':foo' by '(.+)' and stores all the named
# matches defined in $REG->{route_params}{$route}
sub make_regexp {
    my ($route) = @_;
    my @params;
    my $pattern  = $route->{route};

    if (ref($pattern) && $pattern->{regexp}) {
        $pattern = $pattern->{regexp};
    }
    else {
        # look for route with params (/hello/:foo)
        if ($pattern =~ /:/) {
            @params = $pattern =~ /:([^\/]+)/g;
            if (@params) {
#                $REG->{route_params}{$route} = \@params;
                $pattern =~ s/(:[^\/]+)/\(\[\^\/\]\+\)/g;
            }
        }

        # parse wildcards
        $pattern =~ s/\*/\(\[\^\/\]\+\)/g if $pattern =~ /\*/;

        # escape dots
        $pattern =~ s/\./\\\./g if $pattern =~ /\./;
    }

    # escape slashes
    $pattern =~ s/\//\\\//g;

    # return the final regexp
    return '^' . $pattern . '$', @params;
}

1;
