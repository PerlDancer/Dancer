package Dancer::App;
# ABSTRACT: singleton for Dancer apps

=head1 CORE LIBRARY

This class is part of the core, it is provided for developers only.
Dancer users should not need to read this documentation as it
documents internal parts of the code only.

=head1 DESCRIPTION

Manage multiple Dancer applications.

=cut

use strict;
use warnings;
use Carp;
use base 'Dancer::Object';

use Dancer::Config;
use Dancer::ModuleLoader;
use Dancer::Route::Registry;
use Dancer::Logger;

Dancer::App->attributes(qw(name prefix registry settings));

# singleton that saves any app created, we want unicity for app names
my $_apps = {};

=method applications

Returns an array of all running applications (C<Dancer::App> objects).

=cut
sub applications { values %$_apps }

=method app_exists ($name)

Returns a true value if the application identified by the C<$name> is
defined.

=cut
sub app_exists {
    my ( $self, $name ) = @_;
    grep { $_ eq $name } keys %$_apps;
}

=method set_running_app ($name)

Switchs the currently running application.

=cut
sub set_running_app {
    my ($self, $name) = @_;
    my $app = Dancer::App->get($name);
    $app = Dancer::App->new(name => $name) unless defined $app;
    Dancer::App->current($app);
}

=method set_prefix ($prefix, $codeblock)

Set a temporary route prefix to all code present in the C<$codeblock>.

=cut
sub set_prefix {
    my ($self, $prefix, $cb) = @_;
    undef $prefix if defined($prefix) and $prefix eq "/";
    croak "not a valid prefix: `$prefix', must start with a /"
      if defined($prefix) && $prefix !~ /^\//;
    my $previous = Dancer::App->current->prefix;
    Dancer::App->current->prefix($prefix);
    if (ref($cb) eq 'CODE') {
        eval { $cb->() };
        my $e = $@;
        Dancer::App->current->prefix($previous);
        die $e if $e;
    }
    return 1;    # prefix may have been set to undef
}

=method routes ($method)

Returns an array of all routes for a given C<$method> type.

=cut
sub routes {
    my ($self, $method) = @_;
    map { $_->pattern } @{$self->registry->{'routes'}{$method}};
}

=method reload_apps

Reloads all running applications. This method is highly experimental.

=cut
sub reload_apps {
    my ($class) = @_;

    my @missing_modules = grep { not Dancer::ModuleLoader->load($_) }
        qw(Module::Refresh Clone);

    if (not @missing_modules) {

        # saving apps & purging app registries
        my $orig_apps = {};
        while (my ($name, $app) = each %$_apps) {
            $orig_apps->{$name} = $app->clone;
            $app->registry->init();
        }

        # reloading changed modules, getting apps reloaded
        Module::Refresh->refresh;

        # make sure old apps that didn't get reloaded are kept
        while (my ($name, $app) = each %$orig_apps) {
            $_apps->{$name} = $app unless defined $_apps->{$name};
            $_apps->{$name} = $app if $_apps->{$name}->registry->is_empty;
        }

    }
    else {
        carp "Modules required for auto_reload are missing. Install modules"
            . " [@missing_modules] or unset 'auto_reload' in your config file.";
    }
}

=method find_route_through_apps ($request)

Given a C<$request>, this method will search which route can satisfy
it through all defined applications.

=cut

sub find_route_through_apps {
    my ($class, $request) = @_;
    for my $app (Dancer::App->applications) {
        my $route = $app->_find_route($request);
        if ($route) {
            Dancer::App->current($route->app);
            return $route;
        }
        return $route if $route;
    }
    return;
}

sub init {
    my ($self) = @_;
    $self->name('main') unless defined $self->name;

    croak "an app named '" . $self->name . "' already exists"
      if exists $_apps->{$self->name};

    # default values for properties
    $self->settings({});
    $self->_init_registry();

    $_apps->{$self->name} = $self;
}

# singleton that saves the current active Dancer::App object
my $_current;

=method current ($app)

If a C<Dancer::App> is passed in C<$app>, it is set as the current
application. If not, the current application is returned. if none
exists, a new one is created.

=cut
sub current {
    my ($class, $app) = @_;
    return $_current = $app if defined $app;

    if (not defined $_current) {
        $_current = Dancer::App->get('main') || Dancer::App->new();
    }

    return $_current;
}

=method get

Given an app name, returns the app object.

=cut
sub get {
    my ($class, $name) = @_;
    $_apps->{$name};
}

=method setting

Used to set or query a configuration variable on an application. When
querying will go through the local settings and then the main settings
to find the defined value.

=cut

sub setting {
    my $self = shift;

    if ($self->name eq 'main') {
        return (@_ > 1)
          ? Dancer::Config::setting( @_ )
          : Dancer::Config::setting( $_[0] );
    }

    if (@_ > 1) {
        $self->_set_settings(@_)
    } else {
        my $name = shift;
        exists($self->settings->{$name}) ? $self->settings->{$name}
          : Dancer::Config::setting($name);
    }
}

# privates


# instance
sub _find_route {
    my ($self, $request) = @_;
    my $method = lc($request->method);

    # if route cache is enabled, we check if we handled this path before
    if (Dancer::Config::setting('route_cache')) {
        my $route = Dancer::Route::Cache->get->route_from_path($method,
            $request->path_info);

        # NOTE maybe we should cache the match data as well
        if ($route) {
            $route->match($request);
            return $route;
        }
    }

    my @routes = @{$self->registry->routes($method)};

    for my $r (@routes) {
        my $match = $r->match($request);

        if ($match) {
            next if $r->has_options && (not $r->validate_options($request));

            # if we have a route cache, store the result
            if (Dancer::Config::setting('route_cache')) {
                Dancer::Route::Cache->get->store_path($method,
                    $request->path_info => $r);
            }

            return $r;
        }
    }
    return;
}

sub _init_registry {
    my ($self, $reg) = @_;
    $self->registry($reg || Dancer::Route::Registry->new);

}

sub _set_settings {
    my $self = shift;
    die "Odd number of elements in set" unless @_ % 2 == 0;
    while (@_) {
        my $name = shift;
        my $value = shift;

        # FIXME: obviously, we're using a private method from Dancer::Config here, design issue
        $self->settings->{$name} =
          Dancer::Config->_normalize_setting($name => $value);
    }
}

1;
