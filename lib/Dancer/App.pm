package Dancer::App;

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
sub applications { values %$_apps }

sub app_exists {
    my ($self, $name) = @_;
    grep /^$name$/, keys %$_apps;
}

sub set_running_app {
    my ($self, $name) = @_;
    my $app = Dancer::App->get($name);
    $app = Dancer::App->new(name => $name) unless defined $app;
    Dancer::App->current($app);
}

sub set_prefix {
    my ($self, $prefix) = @_;
    croak "not a valid prefix: `$prefix', must start with a /"
      if defined($prefix) && $prefix !~ /^\//;
    Dancer::App->current->prefix($prefix);
    return 1;    # prefix may have been set to undef
}

sub routes {
    my ($self, $method) = @_;
    map { $_->pattern } @{$self->registry->{'routes'}{$method}};
}

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

sub find_route_through_apps {
    my ($class, $request) = @_;
    for my $app (Dancer::App->applications) {
        my $route = $app->find_route($request);
        return $route if $route;
    }
    return;
}

# instance

sub find_route {
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

sub init {
    my ($self) = @_;
    $self->name('main') unless defined $self->name;

    croak "an app named '" . $self->name . "' already exists"
      if exists $_apps->{$self->name};

    # default values for properties
    $self->settings({});
    $self->init_registry();

    $_apps->{$self->name} = $self;
}

sub init_registry {
    my ($self, $reg) = @_;
    $self->registry($reg || Dancer::Route::Registry->new);

}

# singleton that saves the current active Dancer::App object
my $_current;

sub current {
    my ($class, $app) = @_;
    return $_current = $app if defined $app;

    if (not defined $_current) {
        $_current = Dancer::App->get('main') || Dancer::App->new();
    }

    return $_current;
}

sub get {
    my ($class, $name) = @_;
    $_apps->{$name};
}

sub setting {
    my ($self, $name, $value) = @_;

    if ($self->name eq 'main') {
        return (@_ == 3)
          ? Dancer::Config::setting($name => $value)
          : Dancer::Config::setting($name);
    }

    return
      (@_ == 3) ? $self->settings->{$name} =
      Dancer::Config->normalize_setting($name => $value)
      : (
        exists($self->settings->{$name}) ? $self->settings->{$name}
        : Dancer::Config::setting($name)
      );
}

1;
