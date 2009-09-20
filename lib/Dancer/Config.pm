package Dancer::Config;

use strict;
use warnings;
use base 'Exporter';
use vars '@EXPORT_OK';

use Dancer::FileUtils 'path';
use Carp 'confess';

@EXPORT_OK = qw(setting mime_types);

# singleton for storing settings
my $SETTINGS = {};
sub settings { $SETTINGS }

my $setters = {
    logger => sub {
        my ($key, $value)  = @_;
        if (@_ == 2) {
            $SETTINGS->{logger} = $value;
            Dancer::Logger->init;
        }
        else {
            $SETTINGS->{logger};
        }
    },
};

# public accessor for get/set
sub setting {
    my ($setting, $value) = @_;

    # specific setter/getter
    return $setters->{$setting}->(@_) 
        if defined $setters->{$setting};

    # generic setter/getter
    (@_ == 2) 
        ? $SETTINGS->{$setting} = $value
        : $SETTINGS->{$setting} ;
}

sub mime_types {
    my ($ext, $content_type) = @_;
    $SETTINGS->{mime_types} ||= {};
    return $SETTINGS->{mime_types} if @_ == 0;

    return (@_ == 2) 
        ? $SETTINGS->{mime_types}{$ext} = $content_type
        : $SETTINGS->{mime_types}{$ext};
}

sub conffile { path(setting('appdir'), 'config.yml') }

sub environment_file {
    my $env = setting('environment');
    return path(setting('appdir'), 'environments', "$env.yml");
}

sub load { 
    # look for the conffile
    return 1 unless -f conffile;

    # load YAML
    eval "use YAML";
    confess "Configuration file found but YAML is not installed" if $@;
    YAML->import;

    load_default_settings();
    load_settings_from_yaml(conffile);

    my $env = environment_file;
    load_settings_from_yaml($env) if -f $env;

    return 1;
}

sub load_settings_from_yaml {
    my ($file) = @_;

    my $config = YAML::LoadFile($file) or 
        confess "Unable to parse the configuration file: $file";

    foreach my $key (keys %$config) {
        # set values for new settings
        setting($key => $config->{$key});
    }
    return scalar(keys %$config);
}

sub load_default_settings {
    $SETTINGS->{server}       ||= '127.0.0.1';
    $SETTINGS->{port}         ||= '3000';
    $SETTINGS->{content_type} ||= 'text/html';
    $SETTINGS->{charset}      ||= 'UTF-8';
    $SETTINGS->{access_log}   ||= 1;
    $SETTINGS->{daemon}       ||= 0;
    $SETTINGS->{environment}  ||= 'development';
    $SETTINGS->{apphandler}   ||= 'standalone';
    $SETTINGS->{warnings}     ||= 0;
}
load_default_settings();

1;
__END__
=pod

=head1 NAME

Dancer::Config

=head1 DESCRIPTION

Setting registry for Dancer

=head1 SETTINGS

You can change a setting with the keyword B<set>, like the following:

    use Dancer;

    # changing default settings
    set port => 8080;
    set content_type => 'text/plain';
    set access_log => 0;

Here is the list of all supported settings.

=head2 server (UNSUPPORTED)

The IP address or servername to bind to.
This setting is not yet implemented.

=head2 port 

The port Dancer will listen to.

Default value is 3000.

=head2 content_type 

The default content type of outgoing content.
Default value is 'text/html'.

=head2 charset

The default charset of outgoing content.
Default value is 'UTF-8'.

=head2 access_log

If set to 1 (default), Dancer will print on STDEER one line per hit received.

=head2 public 

This is the path of the public directory, where static files are stored. Any
existing file in that directory will be served as a static file, before
mathcing any route.

By default, it points to APPDIR/public where APPDIR is the directory that 
contains your Dancer script.

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@cpan.org>

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=head1 SEE ALSO

L<Dancer>

=cut
