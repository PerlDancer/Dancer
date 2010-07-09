package Dancer::Route::Registry;
use strict;
use warnings;

use base 'Dancer::Object';
use Dancer::Logger;

Dancer::Route::Registry->attributes(qw(
    before_filters
));

sub init {
    my ($self) = @_;
    $self->{routes} = {};
    $self->{before_filters} = [];
    $self->{_state} = 'NEW';
    $self->{_regexps} = {};
}

sub is_new      { $_[0]->{_state} eq 'NEW' }
sub is_compiled { $_[0]->{_state} eq 'COMPILED' }

sub get_regexp {
    my ($self, $name) = @_;
    $self->compile unless defined $self->{_regexps}{$name};
    $self->{_regexps}{$name};
}

sub compile {
    my ($self) = @_;

    foreach my $method (keys %{ $self->{'routes'} }) {
        foreach my $route (@{ $self->routes($method) }) {
            my ($regexp, $variables, $capture) = 
                @{ $self->make_regexp($route) };
            $self->set_regexp($route => $regexp, $variables, $capture);
        }
    }
    $self->{_state} = 'COMPILED';
}

sub set_regexp {
    my ($self, $route, $regexp, $params, $capture) = @_;

    my $key = $route->{'route'};
    $key = $key->{'regexp'} if ref($key);

    $self->{_regexps}{$key} = [ $regexp => $params, $capture ];
}


sub add_prefix {
    my ($self, $route, $prefix) = @_;

    if (ref($route) eq 'HASH' && $route->{regexp}) {
        if ($route->{regexp} !~ /^$prefix/) {
            $route->{regexp} = $prefix . $route->{regexp};
        }
    }
    else {
        $route = $prefix . $route;
        $route =~ s/\/$//; # remove trailing slash
    }
    return $route;
}

# replace any ':foo' by '(.+)' and stores all the named
# matches defined in $REG->{route_params}{$route}
sub make_regexp {
    my ($self, $route) = @_;
    my $capture = 0;
    my @params;
    my $pattern  = $route->{route};

    my $prefix = $route->{prefix};
    $pattern = $self->add_prefix($pattern, $prefix) if $prefix;


    if (ref($pattern) && $pattern->{regexp}) {
        $pattern = $pattern->{regexp};
        $capture = 1;
    }
    else {
        
        # look for route with params (/hello/:foo)
        if ($pattern =~ /:/) {
            @params = $pattern =~ /:([^\/\.]+)/g;
            if (@params) {
                $pattern =~ s/(:[^\/\.]+)/\(\[\^\/\]\+\)/g;
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

sub add_before_filter {
    my ($self, $filter) = @_;

    my $compiled_filter = sub {
        return if Dancer::Response->halted;
        Dancer::Logger::core("entering before filter");
        eval { $filter->() };
        if ($@) {
            my $err = Dancer::Error->new(
                code => 500,
                title => 'Before filter error',
                message => "An error occured while executing the filter: $@");
            return Dancer::halt($err->render);
        }
    };

    push @{ $self->{before_filters} }, $compiled_filter;
}

sub routes {
    my ($self, $method) = @_;

    if ( $method ) {
        my $route = $self->{routes}{$method};
        $route ? return $route : [];
    }
    else {
        return $self->{routes};
    }
}

sub add_route {
    my ($self, %args) = @_;
    $self->{routes}{$args{method}} ||= [];
    push @{ $self->{routes}{$args{method}} }, \%args;
}

# look for a route in the given array
sub find_route {
    my ($self, $r, $reg) = @_;
    foreach my $route (@$reg) {
        return $route if ($r->{route} eq $route->{route});
    }
    return undef;
}

sub merge {
    my ($self, $orig_reg, $new_reg) = @_;
    my $merged_reg = Dancer::Route::Registry->new;

    # walking through all the routes, using the newest when exists
    foreach
      my $method (keys(%{$new_reg->{routes}}), keys(%{$orig_reg->{routes}}))
    {

        # don't work out a method if already done
        next if exists $merged_reg->{routes}{$method};

        my $merged_routes = [];
        my $orig_routes   = $orig_reg->{routes}{$method};
        my $new_routes    = $new_reg->{routes}{$method};

        # walk through all the orig elements, if we have a new version,
        # overwrite it, else, keep the old one.
        foreach my $route (@$orig_routes) {
            my $new = $self->find_route($route, $new_routes);
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
              unless $self->find_route($route, $merged_routes);
        }

        $merged_reg->{routes}{$method} = $merged_routes;
    }

    # NOTE: we have to warn the user about mixing before_filters in different
    # files, that's not supported. Only the last before_filters block is used.
    $merged_reg->{before_filters} =
      (scalar(@{$new_reg->{before_filters}}) > 0)
      ? $new_reg->{before_filters}
      : $orig_reg->{before_filters};

    return $merged_reg;
}

1;
