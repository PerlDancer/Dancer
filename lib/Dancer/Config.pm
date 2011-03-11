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

@EXPORT_OK = qw(setting mime_types);

my $SETTINGS = {};

# mergeable settings
my %MERGEABLE = map { ($_ => 1) } qw( plugins handlers );

sub settings {$SETTINGS}

my $setters = {
    logger => sub {
        my ($setting, $value) = @_;
        Dancer::Logger->init($value, settings());
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
                    Dancer::template($params->{'page'});
                }
            );
        }
    },
    traces => sub {
        my ($setting, $traces) = @_;
        $Carp::Verbose = $traces ? 1 : 0;
    },
};

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

sub mime_types {
    Dancer::Deprecation->deprecated(
        reason => "use 'mime_type' from Dancer.pm",
    );
    my $mime = Dancer::MIME->instance();
    if    (scalar(@_)==2) { $mime->add_mime_type(@_) }
    elsif (scalar(@_)==1) { $mime->mime_type_for(@_) }
    else                  { $mime->aliases           }
}

sub normalize_setting {
    my ($class, $setting, $value) = @_;

    $value = $normalizers->{$setting}->($setting, $value)
      if exists $normalizers->{$setting};

    return $value;
}

# public accessor for get/set
sub setting {
    my ($setting, $value) = @_;

    if (@_ == 2) {
        $value = _set_setting($setting, $value);
        _trigger_hooks($setting, $value);
        return $value;
    }
    else {
        return _get_setting($setting);
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

    load_settings_from_yaml(conffile);

    my $env = environment_file;
    load_settings_from_yaml($env) if -f $env;

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
    $SETTINGS->{access_log}   ||= $ENV{DANCER_ACCESS_LOG}   || 1;
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

Dancer::Config - setting registry for Dancer

=head1 DESCRIPTION

Setting registry for Dancer

=head1 SETTINGS

You can change a setting with the keyword B<set>, like the following:

    use Dancer;

    # changing default settings
    set port => 8080;
    set content_type => 'text/plain';
    set access_log => 0;

A better way of defining settings exists: using YAML file. For this to be
possible, you have to install the L<YAML> module. If a file named B<config.yml>
exists in the application directory, it will be loaded, as a setting group.

The same is done for the environment file located in the B<environments>
directory.

=head1 SUPPORTED SETTINGS

=head2 server (string)

The IP address that the Dancer app should bind to.  Default is 0.0.0.0, i.e.
bind to all available interfaces.

=head2 port (int)

The port Dancer will listen to.

Default value is 3000. This setting can be changed on the command-line with the
B<--port> switch.

=head2 daemon (boolean)

If set to true, runs the standalone webserver in the background.
This setting can be changed on the command-line with the B<--daemon> flag.

=head2 content_type (string)

The default content type of outgoing content.
Default value is 'text/html'.

=head2 charset (string)

This setting does 3 things:

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

=head2 appdir (directory)

This is the path where your application will live.  It's where Dancer
will look by default for your config files, templates and static
content.

It is typically set by C<use Dancer> to use the same directory as your
script.

=head2 public (directory)

This is the directory, where static files are stored. Any existing
file in that directory will be served as a static file, before
matching any route.

By default, it points to $appdir/public.

=head2 views (directory)

This is the directory where your templates and layouts live.  It's the
"view" part of MVC (model, view, controller).

This defaults to $appdir/views.

=head2 layout (string)

The name of the layout to use when rendering view. Dancer will look for
a matching template in the directory $views/layout.

=head2 warnings (boolean)

If set to true, tells Dancer to consider all warnings as blocking errors.

=head2 traces (boolean)

If set to true, Dancer will display full stack traces when a warning or a die
occurs. (Internally sets Carp::Verbose). Default to false.

=head2 log (enum)

Tells which log messages should be actullay logged. Possible values are
B<core>, B<debug>, B<warning> or B<error>.

=over 4

=item B<core> : all messages are logged, including some from Dancer itself

=item B<debug> : all messages are logged

=item B<warning> : only warning and error messages are logged

=item B<error> : only error messages are logged

=back

=head2 show_errors (boolean)

If set to true, Dancer will render a detailed debug screen whenever an error is
catched. If set to false, Dancer will render the default error page, using
$public/$error_code.html if it exists.

=head2 auto_reload (boolean)

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

=head2 session (enum)

This setting lets you enable a session engine for your web application. Be
default, sessions are disabled in Dancer, you must choose a session engine to
use them.

See L<Dancer::Session> for supported engines and their respective configuration.

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@cpan.org> and others,
see the AUTHORS file that comes with this distribution for details.

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=head1 SEE ALSO

L<Dancer>

=cut
