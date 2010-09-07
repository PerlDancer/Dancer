package Dancer::Config;

use strict;
use warnings;
use base 'Exporter';
use vars '@EXPORT_OK';

use Dancer::Template;
use Dancer::ModuleLoader;
use Dancer::FileUtils 'path';
use Carp 'confess';

@EXPORT_OK = qw(setting mime_types);

# singleton for storing settings
my $SETTINGS = {

    # user defined mime types
    mime_types => {},
};
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
                    Dancer::Helpers::template($params->{'page'});
                }
            );
        }
    },
};

# public accessor for get/set
sub setting {
    my ($setting, $value) = @_;

    # run the hook if setter
    $setters->{$setting}->(@_)
      if (@_ == 2) && defined $setters->{$setting};

    # setter/getter
    (@_ == 2)
      ? $SETTINGS->{$setting} = $value
      : $SETTINGS->{$setting};
}

sub mime_types {
    my ($ext, $content_type) = @_;
    $SETTINGS->{mime_types} ||= {};
    return $SETTINGS->{mime_types} if @_ == 0;

    return (@_ == 2)
      ? $SETTINGS->{mime_types}{$ext} = $content_type
      : $SETTINGS->{mime_types}{$ext};
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

    load_default_settings();
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

    my $config = YAML::LoadFile($file)
      or confess "Unable to parse the configuration file: $file";

    @{$SETTINGS}{keys %$config} = values %$config;
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
    $SETTINGS->{environment} 
      ||= $ENV{DANCER_ENVIRONMENT}
      || $ENV{PLACK_ENV}
      || 'development';

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

The default charset of outgoing content. Unicode bodies in HTTP
responses of C<text/*> types will be encoded to this charset. Also,
C<charset=> item will be added to Content-Type response header.

Default value is empty which means don't do anything. HTTP responses
without charset will be interpreted as ISO-8859-1 by most clients.

You can cancel any charset processing by specifying your own charset
in Content-Type header or by ensuring that response body leaves your
handler without Unicode flag set (by encoding it into some 8bit
charset, for example).

Also, since automatically serialized JSON responses have
C<application/json> Content-Type, you should always encode them by
hand.

=head2 public (string)

This is the path of the public directory, where static files are stored. Any
existing file in that directory will be served as a static file, before
mathcing any route.

By default, it points to APPDIR/public where APPDIR is the directory that
contains your Dancer script.

=head2 layout (string)

name of the layout to use when rendering view. Dancer will look for
a matching template in the directory $appdir/views/layout.

=head2 warnings (boolean)

If set to true, tells Dancer to consider all warnings as blocking errors.

=head2 log (enum)

Tells which log messages should be actullay logged. Possible values are
B<debug>, B<warning> or B<error>.

=over 4

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
