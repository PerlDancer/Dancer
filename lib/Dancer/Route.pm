package Dancer::Route;

use strict;
use warnings;
use Dancer::SharedData;
use Dancer::Config 'setting';
use Dancer::Error;

# singleton for stroing the routes defined
my $REG = init_registry();

# accessor for setting up a new route
sub add {
    my ($class, $method, $route, $code) = @_;
    $REG->{routes}{$method} ||= [];
    push @{ $REG->{routes}{$method} }, {method => $method, route => $route, code => $code};
}

# sugar for defining multiple routes at once
sub add_any {
    my ($class, $methods, $route, $code);
    
    # syntax: any ['get', 'post'] => '/route' => sub {};
    if (@_ == 4) {
        ($class, $methods, $route, $code) = @_;
        die "Syntax error, methods should be provided as an ARRAY ref." 
            unless ref($methods) eq 'ARRAY';
    }
    
    # syntax: any '/route' => sub {};
    elsif (@_ == 3) {
        ($class, $route, $code) = @_;
        $methods = [qw(get post delete put)];
    }
    else {
        die "syntax error: see perldoc Dancer for 'any' usage."
    }

    $class->add($_, $route, $code) for @$methods;
    return scalar(@$methods);
}

# helpers needed by the auto_reload feature
sub init_registry     { {routes => {}, before_filters => [] } }
sub purge_all         { $REG = init_registry() }
sub registry          { $REG }
sub set_registry      { $REG = $_[1] }

# look for a route in the given array
sub find_route  { 
    my ($r, $reg) = @_;
    foreach my $route (@$reg) {
        return $route if ($r->{route} eq $route->{route});
    }
    return undef;
}

sub merge_registry    { 
    my ($class, $orig_reg, $new_reg) = @_;
    my $merged_reg = init_registry();

    # walking through all the routes, using the newest when exists
    foreach my $method (
        keys(%{$new_reg->{routes}}), 
        keys(%{$orig_reg->{routes}})
    ) {
        # don't work out a mehtod if already done
        next if exists $merged_reg->{routes}{$method};

        my $merged_routes = [];
        my $orig_routes   = $orig_reg->{routes}{$method};
        my $new_routes    = $new_reg->{routes}{$method};

        # walk through all the orig elements, if we have a new version,
        # overwrite it, else, keep the old one.
        foreach my $route (@$orig_routes) {
            my $new = find_route($route, $new_routes);
            if (defined $new) {
                push @$merged_routes, $new;
            }
            else {
                push @$merged_routes, $route;
            }
        }
        
        # now, walk through all the new elements, looking for a new route
        foreach my $route (@$new_routes) {
            push @$merged_routes, $route 
                unless find_route($route, $merged_routes);
        }

        $merged_reg->{routes}{$method} = $merged_routes;
    }
   
    # NOTE: we have to warn the user about mixing before_filters in different
    # files, that's not supported. Only the last before_filters block is used.
    $merged_reg->{before_filters} = 
        (scalar(@{ $new_reg->{before_filters} }) > 0) 
        ? $new_reg->{before_filters}
        : $orig_reg->{before_filters};

    Dancer::Route->set_registry($merged_reg);
}

# return the first route that matches the path
# TODO: later we'll have to cache this browsing for every path seen
sub find {
    my ($class, $path, $method) = @_;
    $method ||= 'get';
    $method = lc($method);
    
    my $registry = Dancer::Route->registry;

    # browse all matching routes, and return the first one with 
    # a copy of the next matches, so we can call the next route if the 
    # action chooses to pass.
    my $prev;
    my $first_match;
    foreach my $r (@{$registry->{routes}{$method}}) {
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
    my $registry = Dancer::Route->registry;
    $registry->{before_filters} ||= [];
    push @{$registry->{before_filters}}, $filter;
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

    # Log warnings
    if ($warning || $compilation_warning) {
        Dancer::Logger->warning($compilation_warning) 
            if $compilation_warning;
        Dancer::Logger->warning($warning) if $warning;
    }

	# maybe a not retarded way to listen for the exceptions
	# would be good here :)
	# Halt: just stall everything and return the Response singleton
	# useful for the redirect helper
	if(Dancer::Exception::Halt->caught) {
		return Dancer::Response->current;
	} elsif
	# Pass: pass to the next route if available. otherwise, 404.
		(Dancer::Exception::Pass->caught) {
			if ($handler->{'next'}) {
	            return Dancer::Route->call($handler->{'next'});
	        }
	        else {
	            Dancer::SharedData->reset_all();
	            my $error = Dancer::Error->new(code => 404,
	                message => "<h2>Route Resolution Failed</h2>"
	                         . "<p>Last matching route passed, "
	                         . "but no other route left.</p>");
	            return $error->render;
	        }
	# no exceptions? continue the old way, although this
	# mechanism should be dropped in favor of exceptions in the
	# future
	} else {
        # trap errors
	    if ( $@ ||
	        (setting('warnings') && ($warning || $compilation_warning))) {
        
	        Dancer::SharedData->reset_all();

	        my $error;
	        if ($@) {
	            $error = Dancer::Error->new(code => 500,
	                title   => 'Route Handler Error',
	                type    => 'Execution failed',
	                message => $@);

	        }
	        elsif ($warning) {
	            $error = Dancer::Error->new(code => 500,
	                title   => 'Route Handler Error',
	                type    => 'Runtime Warning',
	                message => $warning);

	        }
	        else {
	            $error = Dancer::Error->new(code => 500,
	                title   => 'Route Handler Error',
	                type    => 'Compilation Warning',
	                message => $compilation_warning);
	        }
	        return $error->render;
	    }

	    my $response = Dancer::Response->current;

        # drop the content if this is a HEAD request
        $content = '' if $handler->{method} eq 'head';
        my $ct = $response->{content_type} || setting('content_type');
        my $st = $response->{status} || 200;

        Dancer::SharedData->reset_all();

        return $content if ref($content) eq 'Dancer::Response';
        return Dancer::Response->new(
            status  => $st,
            headers => [ 'Content-Type' => $ct ], 
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
    my $registry = Dancer::Route->registry;

    if (ref($route) eq 'HASH' && $route->{regexp}) {
        $pattern = $route->{regexp};
    }
    else {
        # look for route with params (/hello/:foo)
        @params = $pattern =~ /:([^\/]+)/g;
        if (@params) {
            $registry->{route_params}{$route} = \@params;
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
