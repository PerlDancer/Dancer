package Dancer::App;
our $AUTHORITY = 'cpan:SUKRIA';
# ABSTRACT: Base application class for Dancer.
$Dancer::App::VERSION = '1.3202';
use strict;
use warnings;
use Carp;
use base 'Dancer::Object';

use Dancer::Config;
use Dancer::ModuleLoader;
use Dancer::Route::Registry;
use Dancer::Logger;
use Dancer::Exception qw(:all);
use Dancer::Deprecation;

Dancer::App->attributes(qw(name app_prefix prefix registry settings on_lexical_prefix));

# singleton that saves any app created, we want unicity for app names
my $_apps = {};
sub applications { values %$_apps }

sub app_exists {
    my ( $self, $name ) = @_;
    grep { $_ eq $name } keys %$_apps;
}

sub set_running_app {
    my ($self, $name) = @_;
    my $app = Dancer::App->get($name);
    $app = Dancer::App->new(name => $name) unless defined $app;
    Dancer::App->current($app);
}

sub set_app_prefix {
    my ($self, $prefix) = @_;
    $self->app_prefix($prefix);
    $self->prefix($prefix);
}

sub get_prefix {
    # return the current prefix (if undefined, return an empty string)
    return Dancer::App->current->prefix || '';
}

sub incr_lexical_prefix {
    no warnings;  # for undefined
    $_[0]->on_lexical_prefix( $_[0]->on_lexical_prefix + 1 );
}

sub dec_lexical_prefix {
    $_[0]->on_lexical_prefix( $_[0]->on_lexical_prefix - 1 );
}

sub set_prefix {
    my ($self, $prefix, $cb) = @_;

    undef $prefix if defined($prefix) and $prefix eq "/";

    raise core_app => "not a valid prefix: `$prefix', must start with a /"
      if defined($prefix) && $prefix !~ /^\//;

    my $app_prefix = defined $self->app_prefix ? $self->app_prefix : "";
    my $previous = Dancer::App->current->prefix;

    $prefix ||= "";

    if (Dancer::App->current->on_lexical_prefix) {
        Dancer::App->current->prefix($previous.$prefix);
    } else {
        Dancer::App->current->prefix($app_prefix.$prefix);
    }

    if (ref($cb) eq 'CODE') {
        Dancer::App->current->incr_lexical_prefix;
        eval { $cb->() };
        my $e = $@;
        Dancer::App->current->dec_lexical_prefix;
        Dancer::App->current->prefix($previous);
        die $e if $e;
    }
    return 1;    # prefix may have been set to undef
}

sub routes {
    my ($self, $method) = @_;
    map { $_->pattern } @{$self->registry->{'routes'}{$method}};
}

sub reload_apps {
    my ($class) = @_;

    Dancer::Deprecation->deprecated(
        feature => 'auto_reload',
        reason => 'use plackup -r instead',
    );

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
    for my $app (Dancer::App->current, Dancer::App->applications) {
        my $route = $app->find_route($request);
        if ($route) {
            Dancer::App->current($route->app);
            return $route;
        }
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
            $request->path_info, $self->name);

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
                    $request->path_info => $r, $self->name);
            }

            return $r;
        }
    }
    return;
}

sub init {
    my ($self) = @_;
    $self->name('main') unless defined $self->name;

    raise core_app => "an app named '" . $self->name . "' already exists"
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

sub _set_settings {
    my $self = shift;
    die "Odd number of elements in set" unless @_ % 2 == 0;
    while (@_) {
        my $name = shift;
        my $value = shift;
        $self->settings->{$name} =
          Dancer::Config->normalize_setting($name => $value);
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::App - Base application class for Dancer.

=head1 VERSION

version 1.3202

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
