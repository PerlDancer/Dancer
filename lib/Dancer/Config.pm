package Dancer::Config;

use strict;
use warnings;
use base 'Exporter';
use vars '@EXPORT_OK';

use Dancer::Deprecation;
use Dancer::Template;
use Dancer::ModuleLoader;
use Dancer::FileUtils 'path';
use Carp;

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
        Dancer::Logger->init($value, settings());
    },
    log_file => sub {
        Dancer::Logger->init(setting("logger"), setting());
    },
    session => sub {
        my ($setting, $value) = @_;
        Dancer::Session->init($value, settings());
    },
    template => sub {
        my ($setting, $value) = @_;
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
    import_warnings => sub {
        my ($setting, $value) = @_;
        $^W = $value ? 1 : 0;
    },
    auto_page => sub {
        my ($setting, $auto_page) = @_;
        if ($auto_page) {
            require Dancer::App;
            Dancer::App->current->registry->universal_add(
                'get', '/:page',
                sub {
                    my $params = Dancer::SharedData->request->params;
                    if  (-f Dancer::engine('template')->view($params->{page})) {
                        return Dancer::template($params->{'page'});
                    } else {
                        return Dancer::pass();
                    }
                }
            );
        }
    },
    traces => sub {
        my ($setting, $traces) = @_;
        $Carp::Verbose = $traces ? 1 : 0;
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
          or croak "Charset defined in configuration is wrong : couldn't identify '$charset'";
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
    return path(setting('appdir'), 'environments', "$env.yml");
}

sub init_confdir {
    return setting('confdir') if setting('confdir');
    setting confdir => $ENV{DANCER_CONFDIR} || setting('appdir');
}

sub load {
    init_confdir();

    # look for the conffile
    return 1 unless -f conffile;

    # load YAML
    confess "Configuration file found but YAML is not installed"
      unless Dancer::ModuleLoader->load('YAML');

    if (!$_LOADED{conffile()}) {
        load_settings_from_yaml(conffile);
        $_LOADED{conffile()}++;
    }

    my $env = environment_file;
    if (-f $env && !$_LOADED{$env}) {
        load_settings_from_yaml($env);
        $_LOADED{$env}++;
    }

    foreach my $key (grep { $setters->{$_} } keys %$SETTINGS) {
        $setters->{$key}->($key, $SETTINGS->{$key});
    }

    return 1;
}

sub load_settings_from_yaml {
    my ($file) = @_;

    my $config;

    eval { $config = YAML::LoadFile($file) };
    if (my $err = $@ || (!$config)) {
        confess "Unable to parse the configuration file: $file: $@";
    }

    for my $key (keys %{$config}) {
        if ($MERGEABLE{$key}) {
            my $setting = setting($key);
            $setting->{$_} = $config->{$key}{$_} for keys %{$config->{$key}};
        }
        else {
            _set_setting($key, $config->{$key});
        }
    }

    return scalar(keys %$config);
}

sub load_default_settings {
    $SETTINGS->{server}       ||= $ENV{DANCER_SERVER}       || '0.0.0.0';
    $SETTINGS->{port}         ||= $ENV{DANCER_PORT}         || '3000';
    $SETTINGS->{content_type} ||= $ENV{DANCER_CONTENT_TYPE} || 'text/html';
    $SETTINGS->{charset}      ||= $ENV{DANCER_CHARSET}      || '';
    $SETTINGS->{startup_info} ||= $ENV{DANCER_STARTUP_INFO} || 1;
    $SETTINGS->{daemon}       ||= $ENV{DANCER_DAEMON}       || 0;
    $SETTINGS->{apphandler}   ||= $ENV{DANCER_APPHANDLER}   || 'Standalone';
    $SETTINGS->{warnings}     ||= $ENV{DANCER_WARNINGS}     || 0;
    $SETTINGS->{auto_reload}  ||= $ENV{DANCER_AUTO_RELOAD}  || 0;
    $SETTINGS->{traces}       ||= $ENV{DANCER_TRACES}       || 0;
    $SETTINGS->{logger}       ||= $ENV{DANCER_LOGGER}       || 'file';
    $SETTINGS->{environment} ||=
         $ENV{DANCER_ENVIRONMENT}
      || $ENV{PLACK_ENV}
      || 'development';

    setting $_ => {} for keys %MERGEABLE;
    setting template        => 'simple';
    setting import_warnings => 1;
}

load_default_settings();

1;

__END__

=pod

=head1 NAME

Dancer::Config - how to configure Dancer to suit your needs

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
exists in the application directory, it will be loaded, as a setting group.

The same is done for the environment file located in the B<environments>
directory.

=head1 SUPPORTED SETTINGS

=head2 Run mode and listening interface/port

=head3 server (string)

The IP address that the Dancer app should bind to.  Default is 0.0.0.0, i.e.
bind to all available interfaces.

=head3 port (int)

The port Dancer will listen to.

Default value is 3000. This setting can be changed on the command-line with the
B<--port> switch.

=head3 daemon (boolean)

If set to true, runs the standalone webserver in the background.
This setting can be changed on the command-line with the B<--daemon> flag.

=head3 behind_proxy (boolean)

If set to true, Dancer will look to C<X-Forwarded-Protocol> and
C<X-Forwarded-host> when constructing URLs (for example, when using
C<redirect>. This is useful if your application is behind a proxy.

=head2 Content type / character set

=head3 content_type (string)

The default content type of outgoing content.
Default value is 'text/html'.

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

=head3 default_mime_type (string)

Dancer's L<Dancer::MIME> module uses C<application/data> as a default
mime type. This setting lets the user change it. For example, if you
have a lot of files being served in the B<public> folder that do not
have an extension, and are text files, set the C<default_mime_type> to
C<text/plain>.


=head2 File / directory locations

=head3 environment (string)

This is the name of the environment that should be used. Standard
Dancer applications have a C<environments> folder with specific
configuration files for different environments (usually development
and production environments). They specify different kind of error
reporting, deployment details, etc. These files are read after the
generic C<config.yml> configuration file.

The running environment can be set with:

   set environment => "production";

Note that this variable is also used as a default value if other
values are not defined.

=head3 appdir (directory)

This is the path where your application will live.  It's where Dancer
will look by default for your config files, templates and static
content.

It is typically set by C<use Dancer> to use the same directory as your
script.

=head3 public (directory)

This is the directory, where static files are stored. Any existing
file in that directory will be served as a static file, before
matching any route.

By default, it points to $appdir/public.

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
a matching template in the directory $views/layout.


=head2 Logging, debugging and error handling

=head3 startup_info (boolean)

If set to true, prints a banner at the server start with information such as
versions and the environment (or "dancerfloor").

Conforms to the environment variable DANCER_STARTUP_INFO.

=head3 warnings (boolean)

If set to true, tells Dancer to consider all warnings as blocking errors.

=head3 traces (boolean)

If set to true, Dancer will display full stack traces when a warning or a die
occurs. (Internally sets Carp::Verbose). Default to false.

=head3 log_path (string)

Folder where the ``file C<logger>'' saves logfiles.

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

=head3 log (enum)

Tells which log messages should be actually logged. Possible values are
B<core>, B<debug>, B<warning> or B<error>.

=over 4

=item B<core> : all messages are logged, including some from Dancer itself

=item B<debug> : all messages are logged

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


=head3 auto_reload (boolean)

Requires L<Module::Refresh> and L<Clone>.

If set to true, Dancer will reload the route handlers whenever the file where
they are defined is changed. This is very useful in development environment but
B<should not be enabled in production>. Enabling this flag in production yields
a major negative effect on performance because of L<Module::Refresh>.

When this flag is set, you don't have to restart your webserver whenever you
make a change in a route handler.

Note that L<Module::Refresh> only operates on files in C<%INC>, so if the script
your Dancer app is started from changes, even with auto_reload enabled, you will
still not see the changes reflected until you start your app.

=head2 Session engine

=head3 session (enum)

This setting lets you enable a session engine for your web application. Be
default, sessions are disabled in Dancer, you must choose a session engine to
use them.

See L<Dancer::Session> for supported engines and their respective configuration.

=head3 session_expires

The session expiry time in seconds, or as e.g. "2 hours" (see
L<Dancer::Cookie/expires>.  By default, there is no specific expiry time.

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
will not be able to access to its value.


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

Dancer will honor your C<before_template> code, and all default
variables. They will be accessible and interpolated on automatic
served pages.


=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@cpan.org> and others,
see the AUTHORS file that comes with this distribution for details.

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=head1 SEE ALSO

L<Dancer>

=cut
