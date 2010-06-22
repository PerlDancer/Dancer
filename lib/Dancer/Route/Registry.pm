package Dancer::Route::Registry;
use strict;
use warnings;

use Dancer::Logger;

# instance
use base 'Dancer::Object';

sub init {
    my ($self) = @_;
    $self->{routes} = {};
    $self->{before_filters} = [];
}

# singleton for the current registry
my $_registry = Dancer::Route::Registry->new;


# static
sub get    {$_registry}
sub set    { $_registry = $_[1] }
sub reset  { $_registry = Dancer::Route::Registry->new }

sub before_filters { @{ $_registry->{before_filters} } }
sub add_before_filter {
    my ($class, $filter) = @_;

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

    push @{ $_registry->{before_filters} }, $compiled_filter;
}

sub routes {
    if ( $_[1] ) {
        my $route = $_registry->{routes}{ $_[1] };
        $route ? return $route : [];
    }
    else {
        return $_registry->{routes};
    }
}

sub add_route {
    my ($class, %args) = @_;
    $_registry->{routes}{$args{method}} ||= [];
    push @{ $_registry->{routes}{$args{method}} }, \%args;
}

# look for a route in the given array
sub find_route {
    my ($r, $reg) = @_;
    foreach my $route (@$reg) {
        return $route if ($r->{route} eq $route->{route});
    }
    return undef;
}

sub merge {
    my ($class, $orig_reg, $new_reg) = @_;
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
      (scalar(@{$new_reg->{before_filters}}) > 0)
      ? $new_reg->{before_filters}
      : $orig_reg->{before_filters};

    Dancer::Route::Registry->set($merged_reg);
}

1;
