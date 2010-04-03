package Dancer::Route;

use strict;
use warnings;

use Dancer::SharedData;
use Dancer::Config 'setting';
use Dancer::Error;

use Dancer::Route::Registry;
use Dancer::Route::Builder;
use Dancer::Route::Cache;

my @supported_conditions = qw(agent user_agent host hostname referer);

# main init stuff to setup the route handler
sub init {
    # add the default auto_page route handler if needed
    if (setting('auto_page')) {
        Dancer::Route->add('get', '/:page' => sub {
            my $params = Dancer::SharedData->request->params;
            Dancer::Helpers::template($params->{'page'});
        });
    }

    # compile all the route handlers
    compile_routes();
}


sub route_cache { Dancer::Route::Cache->get() }

sub compile_routes {
    my $routes = Dancer::Route::Registry->routes;
    Dancer::Route::Builder->compile($routes);
}

# accessor for defining a route prefix
my $PREFIX;

sub prefix {
    my ($class, $prefix) = @_;
    return $PREFIX if @_ < 2;

    die "Not a valid prefix, must begins with '/'"
      if defined $prefix && ($prefix !~ /^\//);
    $PREFIX = $prefix;

    return 1;
}

# accessor for setting up a new route
sub add {
    my ($class, $method, $route, $code, $rest) = @_;

    # look for route matching conditions
    my $options;
    if ($rest) {
        die "Invalid route definition" unless ref($code) eq 'HASH';
        $options = $class->_build_condition_regexp($code);
        $code    = $rest;
    }

    # is there a prefix set?
    $route = $class->_add_prefix_if_needed($route);

    Dancer::Route::Registry->add_route(
        method  => $method,
        route   => $route,
        code    => $code,
        options => $options,
    );
}

# sugar for defining multiple routes at once
sub add_any {
    my ($class, $methods, $route, $code, $rest);

    # syntax: any ['get', 'post'] => '/route' => sub {};
    if (@_ == 4) {
        ($class, $methods, $route, $code, $rest) = @_;
        die "Syntax error, methods should be provided as an ARRAY ref."
          unless ref($methods) eq 'ARRAY';
    }

    # syntax: any '/route' => sub {};
    elsif (@_ == 3) {
        ($class, $route, $code, $rest) = @_;
        $methods = [qw(get post delete put)];
    }
    else {
        die "syntax error: see perldoc Dancer for 'any' usage.";
    }

    $class->add($_, $route, $code, $rest) for @$methods;
    return scalar(@$methods);
}

# TODO Registry aliases, maybe we should drop them later
sub registry       { Dancer::Route::Registry->get() }
sub purge_all      { Dancer::Route::Registry->reset() }
sub merge_registry { Dancer::Route::Registry::merge(@_) }

# return the first route that matches the path
sub find {
    my ($class, $path, $method, $request) = @_;
    $method ||= 'get';
    $method = lc($method);

    # First, make sure the routes are compiled,
    # should be done yet by the calling handler,
    # if not, compile them now
    compile_routes() if Dancer::Route::Builder->is_new;

    # if route cache is enabled, we check if we handled this path before
    if (setting('route_cache')) {
        my $route = Dancer::Route->route_cache->route_from_path($method, $path);
        return $route if $route;
    }

    # browse all matching routes, and return the first one with
    # a copy of the next matches, so we can call the next route if the
    # action chooses to pass.
    my $prev;
    my $first_match;
  FIND: foreach my $r (@{Dancer::Route::Registry->routes($method)}) {

        my $params = match($path, $r->{route});
        if ($params) {
            $r->{params} = $params;

            if ($r->{options}) {
                foreach my $opt (keys %{$r->{options}}) {
                    my $re = $r->{options}{$opt};
                    next FIND
                      if (!$request->$opt)
                      || ($request->$opt !~ $re);
                }
            }

            $first_match = $r unless defined $first_match;
            $prev->{'next'} = $r if defined $prev;
            $prev = $r;
        }
    }

    # if zero matches, zero biatches
    return undef unless defined $first_match;

    # if we have a route cache, store the result
    if (setting('route_cache')) {
        Dancer::Route->route_cache->store_path($method, $path => $first_match);
    }

    # return the first matching route, with a copy of the next ones
    return $first_match;
}

sub before_filter {
    my ($class, $filter) = @_;
    Dancer::Route::Registry->add_before_filter($filter);
}
sub before_filters { Dancer::Route::Registry->before_filters }
sub run_before_filters { $_->() for before_filters }

sub build_params {
    my ($class, $handler, $request) = @_;
    $request->_set_route_params($handler->{params} || {});
    return scalar($request->params);
}

# Recursive call of actions through the matching tree
sub call($$) {
    my ($class, $handler) = @_;

    my $request = Dancer::SharedData->request;
    my $params = Dancer::Route->build_params($handler, $request);

    # eval the route handler, and copy the response object
    my $content;
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    eval { $content = $handler->{code}->() };
    my $response_error = $@;
    my $response       = Dancer::Response->current;

    # Log warnings
    Dancer::Logger->warning($warning) if $warning;

    # Pass: pass to the next route if available. otherwise, 404.
    if ($response->{pass}) {
        if ($handler->{'next'}) {
            return Dancer::Route->call($handler->{'next'});
        }
        else {
            my $error = Dancer::Error->new(
                code    => 404,
                message => "<h2>Route Resolution Failed</h2>"
                  . "<p>Last matching route passed, "
                  . "but no other route left.</p>"
            );
            return $error->render;
        }
    }

    # Process the response
    else {

        # trap errors
        if ($response_error || (setting('warnings') && $warning)) {
            my $error;
            if ($response_error) {
                $error = Dancer::Error->new(
                    code    => 500,
                    title   => 'Route Handler Error',
                    type    => 'Execution failed',
                    message => $response_error
                );

            }
            elsif ($warning) {
                $error = Dancer::Error->new(
                    code    => 500,
                    title   => 'Route Handler Error',
                    type    => 'Runtime Warning',
                    message => $warning
                );

            }
            return $error->render;
        }

        # drop the content if this is a HEAD request
        $content = '' if $handler->{method} eq 'head';
        my $ct = $response->{content_type} || setting('content_type');
        my $st = $response->{status}       || 200;
        my $headers = [];
        push @$headers, @{$response->{headers}}, 'Content-Type' => $ct;

        return $content if ref($content) eq 'Dancer::Response';
        return Dancer::Response->new(
            status  => $st,
            headers => $headers,
            content => $content
        );
    }
}

sub match {
    my ($path, $route) = @_;

    my $compiled = get_regexp($route);
    my ($regexp, $variables, $capture) =
      ($compiled->[0], $compiled->[1], $compiled->[2]);

    # If there's no regexp or no path, don't even try to match:
    return if (!$regexp || !$path);

    # first, try the match, and save potential values
    my @values = $path =~ $regexp;

    # if no values found, do not match!
    return 0 unless @values;

    # Hmm, I can has a match?
    my %params;

    # if named variables were found, return params accordingly
    if (@$variables) {
        for (my $i = 0; $i < ~~ @$variables; $i++) {
            $params{$variables->[$i]} = $values[$i];
        }
        return \%params;
    }

    # else, we have unnamed matches, store them in params->{splat}
    # if the route wants capture, if not just return an empty hash
    return $capture ? {splat => \@values} : {};
}

sub get_regexp {
    my ($route) = @_;
    $route = $route->{regexp} if ref($route);

    # the route tree may have changed since the last compilation
    compile_routes() unless Dancer::Route::Builder->is_compiled($route);

    return Dancer::Route::Builder->get_regexp($route);
}

sub _build_condition_regexp {
    my ($class, $conditions) = @_;
    foreach my $cond (keys %$conditions) {
        die "Not a valid option for route matching: `$cond'"
          unless grep /^$cond$/, @supported_conditions;
        my $val = $conditions->{$cond};
        $conditions->{$cond} = qr/$val/;
    }
    return $conditions;
}

sub _add_prefix_if_needed {
    my ($class, $route) = @_;
    my $prefix = $class->prefix;
    return $route unless defined $prefix;

    if (ref($route) eq 'HASH' && $route->{regexp}) {
        if ($route->{regexp} !~ /^$prefix/) {
            $route->{regexp} = $prefix . $route->{regexp};
        }
    }
    else {
        $route = $class->prefix . $route;
    }
    return $route;
}
1;
