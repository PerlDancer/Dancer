package Dancer::Plugin;
use strict;
use warnings;

use Dancer::Config 'setting';

use base 'Exporter';
use vars qw(@EXPORT);

@EXPORT = qw(
    register
    register_plugin
    plugin_setting
);

my @_reserved_keywords = @Dancer::EXPORT;

my $_keywords = {};

sub plugin_setting {
    my $plugin_orig_name = caller();
    my ($plugin_name) = $plugin_orig_name =~ s/Dancer::Plugin:://;
    
    my $settings = setting('plugins');

    foreach (   $plugin_name,    $plugin_orig_name,
             lc $plugin_name, lc $plugin_orig_name) 
    {
        return $settings->{$_}
            if ( exists $settings->{$_} );
    }
    return undef;
}

sub register($$) {
    my ($keyword, $code) = @_;
    my $plugin_name = caller();

    if (grep {$_ eq $keyword} @_reserved_keywords) {
        die "You can't use $keyword, this is a reserved keyword";
    }
    $_keywords->{$plugin_name} ||= [];
    push @{$_keywords->{$plugin_name}}, [$keyword => $code];
}

sub register_plugin {
    my ($application) = shift || caller(1);
    my ($plugin) = caller();

    export_plugin_symbols($plugin => $application); 
}

sub load_plugin {
    my ($plugin) = @_;
    my $application = caller();

    eval "use $plugin";
    die "unable to load plugin '$plugin' : $@" if $@;

    export_plugin_symbols($plugin => $application);
}

sub export_plugin_symbols {
    my ($plugin, $application) = @_;

    for my $keyword (@{ $_keywords->{$plugin} }) {
        my ($name, $code) = @$keyword;
        {
            no strict 'refs';
            *{"${application}::${name}"} = $code;
        }
    }
}

1;
__END__

=pod

=head1 NAME

Dancer::Plugin - helper for writing Dancer plugins

=head1 DESCRIPTION

Create plugins for Dancer

=head1 SYNOPSIS

  package Dancer::Plugin::LinkBlocker;
  use Dancer ':syntax';
  use Dancer::Plugin;

  register block_links_from => sub {
    my $conf = plugin_setting();
    my $re = join ('|', @{$conf->{hosts}});
    before sub {
        if (request->referer && request->referer =~ /$re/) {
            status 403 || $conf->{http_code};
        }
    };
  };

  register_plugin;
  1;

=head1 PLUGINS

You can extend Dancer by writing your own Plugin.

=head2 METHODS

=over 4

=item B<register>

=item B<register_plugin>

=item B<plugin_setting>

Configuration for plugin should be structured like this in the config.yaml of the application:

  plugins:
    plugin_name:
      key: value

If plugin_setting is called inside a plugin, the appropriate configuration will be returned. The plugin_name should be the name of the package, or, if the plugin name is under the Dancer::Plugin:: namespace, the end part of the plugin name.

=back
