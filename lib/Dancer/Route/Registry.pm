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
}

sub before_filter {
    my ($class, $filter) = @_;
    Dancer::App->current->registry->add_before_filter($filter);
}

# replace any ':foo' by '(.+)' and stores all the named
# matches defined in $REG->{route_params}{$route}
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
    my ($self, $route) = @_;
    $self->{routes}{$route->method} ||= [];
    
    my @registered = @{ $self->{routes}{$route->method} };
    my $last = $registered[$#registered];
    $route->set_previous($last) if defined $last;
    push @{ $self->{routes}{$route->method} }, $route;
}

# sugar for add_route

sub register_route {
    my ($class, %args) = @_;
    my $route = Dancer::Route->new(%args);
    Dancer::App->current->registry->add_route($route);
}

# sugar for Dancer.pm
# class, any, ARRAY(0x9864818), '/path', CODE(0x990ac88)
# or
# class, any, '/path', CODE(0x990ac88)
sub any_add {
    my ($class, $pattern, @rest) = @_;

    my @methods = qw(get post put delete options);

    if (ref($pattern) eq 'ARRAY') {
        @methods = @$pattern;
        $pattern = shift @rest;
    }

    die "Syntax error, methods should be provided as an ARRAY ref"
        if grep /^$pattern$/, @methods;

    $class->universal_add($_, $pattern, @rest) for @methods;
}

sub universal_add {
    my ($class, $method, $pattern, @rest) = @_;

    my %options;
    my $code;

    if (@rest == 1) {
        $code = $rest[0];
    }
    else {
        %options = %{$rest[0]};
        $code = $rest[1];
    }

    if ($method eq 'ajax') {
        # FIXME conditions on request->is_ajax
        $class->universal_add('post', $pattern, @rest);
    }

    my %route_args = (
        method => $method,
        code   => $code,
        options => \%options,
        pattern => $pattern,
    );

    $class->register_route(%route_args);
}

# look for a route in the given array
sub find_route {
    my ($self, $r, $reg) = @_;
    foreach my $route (@$reg) {
        return $route if $r->equals($route);
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
