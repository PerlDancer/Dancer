package Dancer::Route;

use strict;
use warnings;

# singleton for stroing the routes defined
my $REG = {};

# accessor for setting up a new route
sub add {
    my ($class, $method, $route, $code) = @_;
    $REG->{routes}{$method} ||= [];
    push @{ $REG->{routes}{$method} }, {route => $route, code => $code};
}

# return the first route that matches the path
# TODO: later we'll have to cache this browsing for every path seen
sub find {
    my ($class, $path, $method) = @_;
    $method ||= 'get';
    $method = lc($method);
    
    # browse all matching routes, and return the first one with 
    # a copy of the next matches, so we can call the next route if the 
    # action chooses to pass.
    my $prev;
    my $first_match;
    foreach my $r (@{$REG->{routes}{$method}}) {
        my $params = match($path, $r->{route});
        if ($params) {
            $r->{params} = $params;
            $first_match = $r unless defined $first_match;
            $prev->{'next'} = $r if defined $prev;
            $prev = $r;
        }
    }
    # if zero matches, zero biatches
    return undef unless defined $first_match;

    # return the first matching route, with a copy of the next ones
    return $first_match;
}

# Recursive call of actions through the matching tree
sub call {
    my ($class, $handler, $params) = @_;
    $params ||= $handler->{params};

    my $content = $handler->{code}->($params); 
    my $response = Dancer::Response->current;
    
    if ($response->{pass}) {
        if ($handler->{'next'}) {
            return Dancer::Route->call($handler->{'next'}, $params);
        }
        else {
            return {
                head => {status => 404, content_type => 'text/plain'},
                content => "pass, but unable to find another matching route",
            };
        }
    }
    else {
        return {
            head => $response, 
            body => $content
        };
    }
}

sub match {
    my ($path, $route) = @_;
    my ($regexp, @variables) = make_regexp_from_route($route);
    
    # first, try the match, and save potential values
    my @values = $path =~ $regexp;
    
    # if no values found, do not match!
    return 0 unless @values;
    
    # Hmm, I can has a match?
    my %params;

    # if named variables where found, return params accordingly
    if (@variables) {
        for (my $i=0; $i< ~~@variables; $i++) {
            $params{$variables[$i]} = $values[$i];
        }
        return \%params;
    }
    
    # else, we have a unnamed matches, store them in params->{splat}
    return { splat => \@values };
}

# replace any ':foo' by '(.+)' and stores all the named 
# matches defined in $REG->{route_params}{$route}
sub make_regexp_from_route {
    my ($route) = @_;
    my @params;
    my $pattern = $route;

    if (ref($route) eq 'HASH' && $route->{regexp}) {
        $pattern = $route->{regexp};
    }
    else {
        # look for route with params (/hello/:foo)
        @params = $pattern =~ /:([^\/]+)/g;
        if (@params) {
            $REG->{route_params}{$route} = \@params;
            $pattern =~ s/(:[^\/]+)/\(\[\^\/\]\+\)/g;
        }
        
        # parse wildcards
        $pattern =~ s/\*/\(\[\^\/\]\+\)/g;

        # escape dots
        $pattern =~ s/\./\\\./g;
    }

    # escape slashes
    $pattern =~ s/\//\\\//g;

    # return the final regexp
    # warn "regexp made is '/$pattern\$'";
    return '^'.$pattern.'$', @params;
}

'Dancer::Route';
