package Dancer::Config;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT:  how to configure Dancer to suit your needs
$Dancer::Config::VERSION = '1.3202';
use strict;
use warnings;
use base 'Exporter';
use vars '@EXPORT_OK';

use Hash::Merge::Simple;
use Dancer::Config::Object 'hashref_to_object';
use Dancer::Deprecation;
use Dancer::Template;
use Dancer::ModuleLoader;
use Dancer::FileUtils 'path';
use Carp;
use Dancer::Exception qw(:all);

use Encode;

@EXPORT_OK = qw(setting);

my $SETTINGS = {};

# mergeable settings
my %MERGEABLE = map { ($_ => 1) } qw( plugins handlers );
my %_LOADED;

sub settings {$SETTINGS}

my $setters = {
    logger => sub {
        my ($setting, $value) = @_;
        require Dancer::Logger;
        Dancer::Logger->init($value, settings());
    },
    log_file => sub {
        require Dancer::Logger;
        Dancer::Logger->init(setting("logger"), settings());
    },
    session => sub {
        my ($setting, $value) = @_;
        require Dancer::Session;
        Dancer::Session->init($value, settings());
    },
    template => sub {
        my ($setting, $value) = @_;
        require Dancer::Template;
        Dancer::Template->init($value, settings());
    },
    route_cache => sub {
        my ($setting, $value) = @_;
        require Dancer::Route::Cache;
        Dancer::Route::Cache->reset();
    },
    serializer => sub {
        my ($setting, $value) = @_;
        require Dancer::Serializer;
        Dancer::Serializer->init($value);
    },
    # This setting has been deprecated in favor of global_warnings.
    import_warnings => sub {
        my ($setting, $value) = @_;

         Dancer::Deprecation->deprecated(
             message => "import_warnings has been deprecated, please use global_warnings instead."
         );

        $^W = $value ? 1 : 0;
    },
    global_warnings => sub {
        my ($setting, $value) = @_;
        $^W = $value ? 1 : 0;
    },
    traces => sub {
        my ($setting, $traces) = @_;
        $Dancer::Exception::Verbose = $traces ? 1 : 0;
    },
};
$setters->{log_path} = $setters->{log_file};

my $normalizers = {
    charset => sub {
        my ($setting, $charset) = @_;
        length($charset || '')
          or return $charset;
        my $encoding = Encode::find_encoding($charset);
        defined $encoding
          or raise core_config => "Charset defined in configuration is wrong : couldn't identify '$charset'";
        my $name = $encoding->name;
        # Perl makes a distinction between the usual perl utf8, and the strict
        # utf8 charset. But we don't want to make this distinction
        $name eq 'utf-8-strict'
          and $name = 'utf-8';
        return $name;
    },
};

sub normalize_setting {
    my ($class, $setting, $value) = @_;

    $value = $normalizers->{$setting}->($setting, $value)
      if exists $normalizers->{$setting};

    return $value;
}

# public accessor for get/set
sub setting {
    if (@_ == 1) {
        return _get_setting(shift @_);
    }
    else {
        # can be useful for debug! Use Logger, instead?
        die "Odd number in 'set' assignment" unless scalar @_ % 2 == 0;

        my $count = 0;
        while (@_) {
            my $setting = shift;
            my $value   = shift;

            _set_setting  ($setting, $value);

            # At the moment, with any kind of hierarchical setter,
            # there is no case where the same trigger will be run more
            # than once. If/when a hierarchical setter is implemented,
            # we should create a list of the hooks that should be run,
            # and run them at the end of this while, only (efficiency
            # purposes).
            _trigger_hooks($setting, $value);
            $count++
        }
        return $count; # just to return anything, the number of items set.
    }
}

sub _trigger_hooks {
    my ($setting, $value) = @_;

    $setters->{$setting}->(@_) if defined $setters->{$setting};
}

sub _set_setting {
    my ($setting, $value) = @_;

    return unless @_ == 2;

    # normalize the value if needed
    $value = Dancer::Config->normalize_setting($setting, $value);
    $SETTINGS->{$setting} = $value;
    return $value;
}

sub _get_setting {
    my $setting = shift;

    return $SETTINGS->{$setting};
}

sub conffile { path(setting('confdir') || setting('appdir'), 'config.yml') }

sub environment_file {
    my $env = setting('environment');
    # XXX for compatibility reason, we duplicate the code from `init_envdir` here
    # we don't know how if some application don't already do some weird stuff like
    # the test in `t/15_plugins/02_config.t`.
    my $envdir = setting('envdir') || path(setting('appdir'), 'environments');
    return path($envdir, "$env.yml");
}

sub init_confdir {
    return setting('confdir') if setting('confdir');
    setting confdir => $ENV{DANCER_CONFDIR} || setting('appdir');
}

sub init_envdir {
    return setting('envdir') if setting('envdir');
    my $appdirpath = defined setting('appdir')                 ?
                     path( setting('appdir'), 'environments' ) :
                     path('environments');

    setting envdir => $ENV{DANCER_ENVDIR} || $appdirpath;
}

sub load {
    init_confdir();
    init_envdir();

    # look for the conffile
    return 1 unless -f conffile;

    # load YAML
    my $module = $SETTINGS->{engines}{YAML}{module} || 'YAML';

    my ( $result, $error ) = Dancer::ModuleLoader->load($module);
    confess "Configuration file found but could not load $module: $error"
        unless $result;

    unless ($_LOADED{conffile()}) {
        load_settings_from_yaml(conffile);
        $_LOADED{conffile()}++;
    }

    my $env = environment_file;

    # don't load the same env twice
    unless( $_LOADED{$env} ) {
        if (-f $env ) {
            load_settings_from_yaml($env);
            $_LOADED{$env}++;
        }
        elsif (setting('require_environment')) {
            # failed to load the env file, and the main config said we needed it.
            confess "Could not load environment file '$env', and require_environment is set";
        }
    }

    foreach my $key (grep { $setters->{$_} } keys %$SETTINGS) {
        $setters->{$key}->($key, $SETTINGS->{$key});
    }
    if ( $SETTINGS->{strict_config} ) {
        $SETTINGS = hashref_to_object($SETTINGS);
    }

    return 1;
}

sub load_settings_from_yaml {
    my ($file) = @_;

    my $config = eval { YAML::LoadFile($file) }
        or confess "Unable to parse the configuration file: $file: $@";

    $SETTINGS = Hash::Merge::Simple::merge( $SETTINGS, {
        map {
            $_ => Dancer::Config->normalize_setting( $_, $config->{$_} )
        } keys %$config
    } );

    return scalar keys %$config;
}

sub load_default_settings {
    $SETTINGS->{server}        ||= $ENV{DANCER_SERVER}        || '0.0.0.0';
    $SETTINGS->{port}          ||= $ENV{DANCER_PORT}          || '3000';
    $SETTINGS->{content_type}  ||= $ENV{DANCER_CONTENT_TYPE}  || 'text/html';
    $SETTINGS->{charset}       ||= $ENV{DANCER_CHARSET}       || '';
    $SETTINGS->{startup_info}  ||= !$ENV{DANCER_NO_STARTUP_INFO};
    $SETTINGS->{daemon}        ||= $ENV{DANCER_DAEMON}        || 0;
    $SETTINGS->{apphandler}    ||= $ENV{DANCER_APPHANDLER}    || 'Standalone';
    $SETTINGS->{warnings}      ||= $ENV{DANCER_WARNINGS}      || 0;
    $SETTINGS->{auto_reload}   ||= $ENV{DANCER_AUTO_RELOAD}   || 0;
    $SETTINGS->{traces}        ||= $ENV{DANCER_TRACES}        || 0;
    $SETTINGS->{server_tokens} ||= !$ENV{DANCER_NO_SERVER_TOKENS};
    $SETTINGS->{logger}        ||= $ENV{DANCER_LOGGER}        || 'file';
    $SETTINGS->{environment}   ||=
         $ENV{DANCER_ENVIRONMENT}
      || $ENV{PLACK_ENV}
      || 'development';

    setting $_ => {} for keys %MERGEABLE;
    setting template        => 'simple';
}

load_default_settings();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Config - how to configure Dancer to suit your needs

=head1 VERSION

version 1.3202

=head1 DESCRIPTION

Dancer::Config handles reading and changing the configuration of your Dancer
apps.  The documentation for this module aims to describe how to change
settings, and which settings are available.

=head1 SETTINGS

You can change a setting with the keyword B<set>, like the following:

    use Dancer;

    # changing default settings
    set port         => 8080;
    set content_type => 'text/plain';
    set startup_info => 0;

A better way of defining settings exists: using YAML file. For this to be
possible, you have to install the L<YAML> module. If a file named B<config.yml>
exists in the application directory it will be loaded as a setting group.

The same is done for the environment file located in the B<environments>
directory.

To fetch the available configuration values use the B<config> keyword that returns
a reference to a hash:

    my $port   = config->{port};
    my $appdir = config->{appdir};

By default, the module L<YAML> will be used to parse the configuration files.
If desired, it is possible to use L<YAML::XS> instead by changing the YAML
engine configuration in the application code:

    config->{engines}{YAML}{module} = 'YAML::XS';

See L<Dancer::Serializer::YAML> for more details.

=head1 SUPPORTED SETTINGS

=head2 Run mode and listening interface/port

=head3 server (string)

The IP address that the Dancer app should bind to.  Default is 0.0.0.0, i.e.
bind to all available interfaces.

Can also be set with environment variable L<DANCER_SERVER|/"ENVIRONMENT VARIABLES">

=head3 port (int)

The port Dancer will listen to.

Default value is 3000. This setting can be changed on the command-line with the
B<--port> switch.

Can also be set with environment variable L<DANCER_PORT|/"ENVIRONMENT VARIABLES">

=head3 daemon (boolean)

If set to true, runs the standalone webserver in the background.
This setting can be changed on the command-line with the B<--daemon> flag.

Can also be enabled by setting environment variable L<DANCER_DAEMON|/"ENVIRONMENT VARIABLES"> to a true value. 

=head3 behind_proxy (boolean)

If set to true, Dancer will look to C<X-Forwarded-Protocol> and
C<X-Forwarded-host> when constructing URLs (for example, when using
C<redirect>. This is useful if your application is behind a proxy.

=head2 Content type / character set

=head3 content_type (string)

The default content type of outgoing content.
Default value is 'text/html'.

Can also be set with environment variable L<DANCER_CONTENT_TYPE|/"ENVIRONMENT VARIABLES">

=head3 charset (string)

This setting has multiple effects:

=over

=item *

It sets the default charset of outgoing content. C<charset=> item will be
added to Content-Type response header.

=item *

It makes Unicode bodies in HTTP responses of C<text/*> types to be encoded to
this charset.

=item *

It also indicates to Dancer in which charset the static files and templates are
encoded.

=item *

If you're using L<Dancer::Plugin::Database>, UTF-8 support will automatically be
enabled for your database - see 
L<Dancer::Plugin::Database/"AUTOMATIC UTF-8 SUPPORT">

=back

Default value is empty which means don't do anything. HTTP responses
without charset will be interpreted as ISO-8859-1 by most clients.

You can cancel any charset processing by specifying your own charset
in Content-Type header or by ensuring that response body leaves your
handler without Unicode flag set (by encoding it into some 8bit
charset, for example).

Also, since automatically serialized JSON responses have
C<application/json> Content-Type, you should always encode them by
hand.

Can also be set with environment variable L<DANCER_CHARSET|/"ENVIRONMENT VARIABLES">

=head3 default_mime_type (string)

Dancer's L<Dancer::MIME> module uses C<application/data> as a default
mime type. This setting lets the user change it. For example, if you
have a lot of files being served in the B<public> folder that do not
have an extension, and are text files, set the C<default_mime_type> to
C<text/plain>.

=head2 File / directory locations

=head3 environment (string)

This is the name of the environment that should be used. Standard
Dancer applications have an C<environments> folder with specific
configuration files for different environments (usually development
and production environments). They specify different kinds of error
reporting, deployment details, etc. These files are read after the
generic C<config.yml> configuration file.

The running environment can be set with:

   set environment => "production";

Note that this variable is also used as a default value if other
values are not defined.

Can also be set with environment variable L<DANCER_ENVIRONMENT|/"ENVIRONMENT VARIABLES">

=head3 appdir (directory)

This is the path where your application will live.  It's where Dancer
will look by default for your config files, templates and static
content.

It is typically set by C<use Dancer> to use the same directory as your
script.

Can also be set with environment variable L<DANCER_APPDIR|/"ENVIRONMENT VARIABLES">

=head3 public (directory)

This is the directory, where static files are stored. Any existing
file in that directory will be served as a static file, before
matching any route.

By default it points to $appdir/public.

=head3 views (directory)

This is the directory where your templates and layouts live.  It's the
"view" part of MVC (model, view, controller).

This defaults to $appdir/views.

=head2 Templating & layouts

=head3 template

Allows you to configure which template engine should be used.  For instance, to
use Template Toolkit, add the following to C<config.yml>:

    template: template_toolkit

=head3 layout (string)

The name of the layout to use when rendering view. Dancer will look for
a matching template in the directory $views/layouts.

Your can override the default layout using the third argument of the
C<template> keyword. Check C<Dancer> manpage for details.

=head2 Logging, debugging and error handling

=head3 strict_config (boolean, default: false)

If true, C<config> will return an object instead of a hash reference. See
L<Dancer::Config::Object> for more information.

=head3 global_warnings (boolean, default: false)

If true, C<use warnings> will be in effect for all modules and scripts loaded
by your Dancer application. Default is false.

Can also be enabled by setting the environment variable L<DANCER_WARNINGS|/"ENVIRONMENT VARIABLES"> to
a true value.

=head3 startup_info (boolean)

If set to true (the default), prints a banner at server startup with information such as
versions and the environment (or "dancefloor").

Can also be disabled by setting the environment variable L<DANCER_NO_STARTUP_INFO|/"ENVIRONMENT VARIABLES"> to
a true value.

=head3 warnings (boolean)

If set to true, tells Dancer to consider all warnings as blocking errors. Default is false.

=head3 traces (boolean)

If set to true, Dancer will display full stack traces when a warning or a die
occurs. (Internally sets Carp::Verbose). Default is false.

Can also be enabled by setting environment variable L<DANCER_TRACES|/"ENVIRONMENT VARIABLES"> to a true value.

=head3 require_environment (boolean)

If set to true, Dancer will fail during startup if your environment file is
missing or can't be read. This is especially useful in production when you
have things like memcached settings that need to be set per-environment.
Defaults to false.

=head3 server_tokens (boolean)

If set to true (the default), Dancer will add an "X-Powered-By" header and also append
the Dancer version to the "Server" header.

Can also be disabled by setting the environment variable L<DANCER_NO_SERVER_TOKENS|/"ENVIRONMENT VARIABLES"> to
a true value.

=head3 log_path (string)

Folder where the ``file C<logger>'' saves log files.

=head3 log_file (string)

Name of the file to create when ``file C<logger>'' is active. It
defaults to the C<environment> setting contents.

=head3 logger (enum)

Select which logger to use.  For example, to write to log files in C<log_path>:

    logger: file

Or to direct log messages to the console from which you started your Dancer app
in standalone mode,

    logger: console

Various other logger backends are available on CPAN, including 
L<Dancer::Logger::Syslog>, L<Dancer::Logger::Log4perl>, L<Dancer::Logger::PSGI>
(which can, with the aid of Plack middlewares, send log messages to a browser's
console window) and others.

Can also be set with environment variable L<DANCER_LOGGER|/"ENVIRONMENT VARIABLES">

=head3 log (enum)

Tells which log messages should be actually logged. Possible values are
B<core>, B<debug>, B<warning> or B<error>.

=over 4

=item B<core> : all messages are logged, including some from Dancer itself

=item B<debug> : all messages are logged

=item B<info> : only info, warning and error messages are logged

=item B<warning> : only warning and error messages are logged

=item B<error> : only error messages are logged

=back

During development, you'll probably want to use C<debug> to see your own debug
messages, and C<core> if you need to see what Dancer is doing.  In production,
you'll likely want C<error> or C<warning> only, for less-chatty logs.

=head3 show_errors (boolean)

If set to true, Dancer will render a detailed debug screen whenever an error is
caught. If set to false, Dancer will render the default error page, using
$public/$error_code.html if it exists or the template specified by the
C<error_template> setting.

The error screen attempts to sanitise sensitive looking information (passwords /
card numbers in the request, etc) but you still should not have show_errors
enabled whilst in production, as there is still a risk of divulging details.

=head3 error_template (template path)

This setting lets you specify a template to be used in case of runtime
error. At the present moment the template can use three variables:

=over 4

=item B<title>

The error title.

=item B<message>

The error message.

=item B<code>

The code throwing that error.

=back

=head2 Session engine

=head3 session (enum)

This setting lets you enable a session engine for your web application. By
default sessions are disabled in Dancer. You must choose a session engine to
use them.

See L<Dancer::Session> for supported engines and their respective configuration.

=head3 session_expires

The session expiry time in seconds, or as e.g. "2 hours" (see
L<Dancer::Cookie/expires>.  By default there is no specific expiry time.

=head3 session_name

The name of the cookie to store the session ID in.  Defaults to
C<dancer.session>.  This can be overridden by certain session engines.

=head3 session_secure

The user's session ID is stored in a cookie.  If the C<session_secure> setting
is set to a true value, the cookie will be marked as secure, meaning it should
only be sent over HTTPS connections.

=head3 session_is_http_only

This setting defaults to 1 and instructs the session cookie to be
created with the C<HttpOnly> option active, meaning that JavaScript
will not be able to access its value.

=head3 session_domain

Allows you to set the domain property on the cookie, which will
override the default.  This is useful for setting the session cookie's
domain to something like C<.domain.com> so that the same cookie will
be applicable and usable across subdomains of a base domain.

=head2 auto_page (boolean)

For simple pages where you're not doing anything dynamic, but still
want to use the template engine to provide headers etc, you can use
the auto_page feature to avoid the need to create a route for each
page.

With C<auto_page> enabled, if the requested path does not match any
specific route, Dancer will check in the views directory for a
matching template, and use it to satisfy the request if found.

Simply enable auto_page in your config:

    auto_page: 1

Then, if you request C</foo/bar>, Dancer will look in the views dir for
C</foo/bar.tt>.

Dancer will honor your C<before_template_render> code, and all default
variables. They will be accessible and interpolated on automaticly-served pages.

The pages served this way will have C<Content-Type> set to C<text/html>,
so don't use the feature for anything else.

=head2 Route caching

=head3 route_cache (boolean)

If true, enables route caching (for quicker route resolution on larger apps - not caching
of responses).  See L<Dancer::Route::Cache> for details. Default is false.

=head3 route_cache_size_limit (bytes)

Maximum size of route cache (e.g. 1024, 2M). Defaults to 10M (10MB) - see L<Dancer::Route::Cache>

=head3 route_cache_path_limit (number)

Maximum number of routes to cache. Defaults to 600 - see L<Dancer::Route::Cache>

=head2 DANCER_CONFDIR and DANCER_ENVDIR

It's possible to set the configuration directory and environment directory using these two
environment variables. Setting `DANCER_CONFDIR` will have the same effect as doing

    set confdir => '/path/to/confdir'

and setting `DANCER_ENVDIR` will be similar to:

    set envdir => '/path/to/environments'

=head1 ENVIRONMENT VARIABLES

Some settings can be provided via environment variables at runtime, as detailed above; a full list of environment variables you can use follows.

L<DANCER_APPDIR|/"appdir (directory)">

DANCER_APPHANDLER a L<Dancer::Handler::*> by default L<Dancer::Handler::Standalone> 

L<DANCER_AUTO_RELOAD|/"auto_reload (boolean)">

L<DANCER_CHARSET|/"charset (string)">

DANCER_CONFDIR

L<DANCER_CONTENT_TYPE|/"content_type (string)">

L<DANCER_DAEMON|/"daemon (boolean)">

DANCER_ENVDIR

L<DANCER_ENVIRONMENT|/"environment (string)">

L<DANCER_NO_SERVER_TOKENS|/"server_tokens (boolean)">

L<DANCER_NO_STARTUP_INFO|/"startup_info (boolean)">

L<DANCER_LOGGER|/"logger (enum)">

L<DANCER_PORT|/"port (int)">

L<DANCER_SERVER|/"server (string)">

L<DANCER_TRACES|/"traces (boolean)">

L<DANCER_WARNINGS|/"global_warnings (boolean, default: false)">

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@cpan.org> and others,
see the AUTHORS file that comes with this distribution for details.

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=head1 SEE ALSO

L<Dancer>

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
