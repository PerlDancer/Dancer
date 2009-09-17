package Dancer::Route;

use strict;
use warnings;
use Dancer::SharedData;
use Dancer::Config 'setting';

# singleton for stroing the routes defined
my $REG = { routes => {}, before_filters => [] };

# accessor for setting up a new route
sub add {
    my ($class, $method, $route, $code) = @_;
    $REG->{routes}{$method} ||= [];
    push @{ $REG->{routes}{$method} }, {method => $method, route => $route, code => $code};
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

sub before_filter {
    my ($class, $filter) = @_; 
    $REG->{before_filters} ||= [];
    push @{$REG->{before_filters}}, $filter;
}

sub before_filters { @{$REG->{before_filters}} }
sub run_before_filters { $_->() for before_filters }

sub build_params {
    my ($handler, $request) = @_;
    
    my $current_params = Dancer::SharedData->params || {};
    my $request_params = scalar($request->Vars) || {};
    my $route_params = $handler->{params} || {};

    return { 
        %{$request_params}, 
        %{$route_params}, 
        %{$current_params},
    };
}

# We catch compilation-time warnings here
my $COMPILATION_WARNING;
sub warning { 
    (@_ == 1) 
        ? $COMPILATION_WARNING = $_[0] 
        : $COMPILATION_WARNING;
}
BEGIN { $SIG{'__WARN__'} = sub { warning($_[0]) } }

# Recursive call of actions through the matching tree
sub call($$) {
    my ($class, $handler) = @_;
    
    my $cgi = Dancer::SharedData->cgi;
    my $params = build_params($handler, $cgi);
    Dancer::SharedData->params($params);

    my $content;
    my $warning; # reset any previous warning seen
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    eval { $content = $handler->{code}->() };
    my $compilation_warning = warning;

    # trap errors
    if ( $@ || 
        (setting('warnings') && ($warning || $compilation_warning))) {

        my $message = "Route Handler Error\n\n";
        $message .= "Compilation warning: $compilation_warning\n" 
            if $compilation_warning;
        $message .= "Runtime Warning: $warning\n" if $warning;
        $message .= "Runtime Error: $@\n" if $@;

        Dancer::SharedData->reset_all();
        return Dancer::Response->new(
            status  => 500,
            headers => {'Content-Type' => 'text/plain'},
            content => $message);
    }

    my $response = Dancer::Response->current;

    if ($response->{pass}) {
        if ($handler->{'next'}) {
            return Dancer::Route->call($handler->{'next'});
        }
        else {
            Dancer::SharedData->reset_all();
            return Dancer::Response->new(
                status  => 404,
                headers => {'Content-Type' => 'text/plain'},
                content => "route passed, but unable to find another matching route");
        }
    }
    else {
        # drop the content if this is a HEAD request
        $content = '' if $handler->{method} eq 'head';
        my $ct = $response->{content_type} || setting('content_type');
        my $st = $response->{status} || 200;
        Dancer::SharedData->reset_all();

        return Dancer::Response->new(
            status  => $st,
            headers => { 'Content-Type' => $ct }, 
            content => $content);
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
