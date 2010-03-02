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
            my ($regexp, $variables, $capture) = @{ make_regexp($route) };
            set_regexp($route => $regexp, $variables, $capture);
        }
    }
    $_COMPILED_ROUTES->{_state} = 'DONE';
}

sub set_regexp {
    my ($route, $regexp, $params, $capture) = @_;

    my $key = $route->{'route'};
    $key = $key->{'regexp'} if ref($key);

    #warn "saving route for $key";
    $_COMPILED_ROUTES->{$key} = [ $regexp => $params, $capture ];
}


# replace any ':foo' by '(.+)' and stores all the named
# matches defined in $REG->{route_params}{$route}
sub make_regexp {
    my ($route) = @_;
    my $capture = 0;
    my @params;
    my $pattern  = $route->{route};

    if (ref($pattern) && $pattern->{regexp}) {
        $pattern = $pattern->{regexp};
        $capture = 1;
    }
    else {
        # look for route with params (/hello/:foo)
        if ($pattern =~ /:/) {
            @params = $pattern =~ /:([^\/]+)/g;
            if (@params) {
                $pattern =~ s/(:[^\/]+)/\(\[\^\/\]\+\)/g;
                $capture = 1;
            }
        }

        # parse wildcards
        if ($pattern =~ /\*/) {
            $pattern =~ s/\*/\(\[\^\/\]\+\)/g;
            $capture = 1;
        }

        # escape dots
        $pattern =~ s/\./\\\./g if $pattern =~ /\./;
    }

    # escape slashes
    $pattern =~ s/\//\\\//g;

    # return the final regexp, plus meta information
    return ["^${pattern}\$", \@params, $capture];
}

1;
