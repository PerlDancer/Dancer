package Dancer::Route::Cache;

use strict;
use warnings;
use Carp;

use base 'Dancer::Object';

use vars '$VERSION';

use Dancer::Config 'setting';
use Dancer::Error;
use Dancer::Exception qw(:all);

$VERSION = '0.01';
Dancer::Route::Cache->attributes('size_limit', 'path_limit');

# static

# singleton for the current cache object
my $_cache;

sub get {$_cache}

sub reset {
    $_cache = Dancer::Route::Cache->new();
    $_cache->{size_limit} = setting('route_cache_size_limit')
      if defined setting('route_cache_size_limit');
    $_cache->{path_limit} = setting('route_cache_path_limit')
      if defined setting('route_cache_path_limit');
}

# instance

sub init {
    my ($self, %args) = @_;
    $self->build_size_limit($args{'size_limit'} || '10M');
    $self->build_path_limit($args{'path_limit'} || 600);
}

sub build_path_limit {
    my ($self, $limit) = @_;
    if ($limit) {
        $self->{'path_limit'} = $limit;
    }

    return $self->{'path_limit'};
}

sub build_size_limit {
    my ($self, $limit) = @_;
    if ($limit) {
        $self->{'size_limit'} = $self->parse_size($limit);
    }

    return $self->{'size_limit'};
}

sub parse_size {
    my ($self, $size) = @_;

    if ($size =~ /^(\d+)(K|M|G)?$/i) {
        my $base = $1;
        if (my $ext = $2) {
            $ext eq 'K' and return $base * 1024**1;
            $ext eq 'M' and return $base * 1024**2;
            $ext eq 'G' and return $base * 1024**3;
        }

        return $base;
    }
}

sub route_from_path {
    my ($self, $method, $path) = @_;

    $method && $path
      or raise core_route => "Missing method or path";

    return $self->{'cache'}{$method}{$path} || undef;
}

sub store_path {
    my ($self, $method, $path, $route) = @_;

    $method && $path && $route
      or raise core_route => "Missing method, path or route";

    $self->{'cache'}{$method}{$path} = $route;

    push @{$self->{'cache_array'}}, [$method, $path];

    if (my $limit = $self->size_limit) {
        while ($self->route_cache_size() > $limit) {
            my ($method, $path) = @{shift @{$self->{'cache_array'}}};
            delete $self->{'cache'}{$method}{$path};
        }
    }

    if (my $limit = $self->path_limit) {
        while ($self->route_cache_paths() > $limit) {
            my ($method, $path) = @{shift @{$self->{'cache_array'}}};
            delete $self->{'cache'}{$method}{$path};
        }
    }
}

sub route_cache_size {
    my $self  = shift;
    my %cache = %{$self->{'cache'}};
    my $size  = 0;

    use bytes;

    foreach my $method (keys %cache) {
        $size += length $method;

        foreach my $path (keys %{$cache{$method}}) {
            $size += length $path;
            $size += length $cache{$method}{$path};
        }
    }

    no bytes;

    return $size;
}

sub route_cache_paths {
    my $self = shift;
    my %cache = $self->{'cache'} ? %{$self->{'cache'}} : ();

    return scalar map { keys %{$cache{$_}} } keys %cache;
}

1;

__END__

=head1 NAME

Dancer::Route::Cache - route caching mechanism for L<Dancer>

=head1 SYNOPSIS

    my $cache = Dancer::Route::Cache->new(
        path_limit => 300, # optional
    );

    # storing a path
    # /new/item/ is the path, $route is a compiled route
    $cache->store_path( 'get', '/new/item/', $route );
    my $cached_route = $cache->route_from_path('/new/item/');

=head1 DESCRIPTION

When L<Dancer> first starts, it has to compile a regexp list of all the routes.
Then, on each request it goes over the compiled routes list and tries to compare
the requested path to a route.

A major drawback is that L<Dancer> has to go over the matching on every request,
which (especially on CGI-based applications) can be very time consuming.

The caching mechanism allows one to cache some requests to specific routes (but
B<NOT> specific results) and run those routes on a specific path. This allows us
to speed up L<Dancer> quite a lot.

=head1 METHODS/SUBROUTINES

=head2 new(@args)

Creates a new route cache object.

    my $cache = Dancer::Route::Cache->new(
        path_limit => 100,   # only 100 paths will be cached
        size_limit => '30M', # max size for cache is 30MB
    );

Please check the C<ATTRIBUTES> section below to learn about the arguments for
C<new()>.

=head2 route_from_path($path)

Fetches the route from the path in the cache.

=head2 store_path( $method, $path => $route )

Stores the route in the cache according to the path and $method.

For developers: the reason we're using an object for this and not directly using
the registry hash is because we need to enforce the limits.

=head2 parse_size($size)

Parses the size wanted to bytes. It can handle Kilobytes, Megabytes or
Gigabytes.

B<NOTICE:> handles bytes, not bits!

    my $bytes = $cache->parse_size('30M');

    # doesn't need an existing object
    $bytes = Dancer::Route::Cache->parse_size('300G'); # works this way too

=head2 route_cache_size

Returns a rough calculation the size of the cache. This is used to enforce the
size limit.

=head2 route_cache_paths

Returns all the paths in the cache. This is used to enforce the path limit.

=head1 ATTRIBUTES

=head2 size_limit($limit)

Allows one to set a size limit of the cache.

Returns the limit (post-set).

    $cache->size_limit('10K');      # sets limit
    my $limit = $cache->size_limit; # gets limit

=head2 path_limit($limit)

A path limit. That is, the amount of paths that whose routes will be cached.

Returns the limit (post-set).

    $cache->path_limit('100');      # sets limit
    my $limit = $cache->path_limit; # gets limit

=head1 AUTHOR

Sawyer X

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Sawyer X.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

