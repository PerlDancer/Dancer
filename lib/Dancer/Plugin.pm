package Dancer::Plugin;
use strict;
use warnings;
use Carp;

use base 'Exporter';
use Dancer::Config 'setting';
use Dancer::Hook;
use Dancer::Exception qw(:all);

use base 'Exporter';
use vars qw(@EXPORT);

@EXPORT = qw(
  add_hook
  register
  register_plugin
  plugin_setting
);

sub register($&);

my $_keywords = {};

sub add_hook { Dancer::Hook->new(@_) }

sub plugin_setting {
    my $plugin_orig_name = caller();
    (my $plugin_name = $plugin_orig_name) =~ s/Dancer::Plugin:://;

    return setting('plugins')->{$plugin_name} ||= {};
}

sub register($&) {
    my ($keyword, $code) = @_;
    my $plugin_name = caller();

    $keyword =~ /^[a-zA-Z_]+[a-zA-Z0-9_]*$/
      or raise core_plugin => "You can't use '$keyword', it is an invalid name"
        . " (it should match ^[a-zA-Z_]+[a-zA-Z0-9_]*$ )";

    if (
        grep { $_ eq $keyword } 
        map  { s/^(?:\$|%|&|@|\*)//; $_ } 
        (@Dancer::EXPORT, @Dancer::EXPORT_OK)
    ) {
        raise core_plugin => "You can't use '$keyword', this is a reserved keyword";
    }
    while (my ($plugin, $keywords) = each %$_keywords) {
        if (grep { $_->[0] eq $keyword } @$keywords) {
            raise core_plugin => "You can't use $keyword, "
                . "this is a keyword reserved by $plugin";
        }
    }

    $_keywords->{$plugin_name} ||= [];
    push @{$_keywords->{$plugin_name}}, [$keyword => $code];
}

sub register_plugin {
    my ($application) = shift || caller(1);
    my ($plugin) = caller();

    my @symbols = set_plugin_symbols($plugin);
    {
        no strict 'refs';
        # tried to use unshift, but it yields an undef warning on $plugin (perl v5.12.1)
        @{"${plugin}::ISA"} = ('Exporter', 'Dancer::Plugin', @{"${plugin}::ISA"});
        push @{"${plugin}::EXPORT"}, @symbols;
    }
    return 1;
}

sub set_plugin_symbols {
    my ($plugin) = @_;

    for my $keyword (@{$_keywords->{$plugin}}) {
        my ($name, $code) = @$keyword;
        {
            no strict 'refs';
            *{"${plugin}::${name}"} = $code;
        }
    }
    return map { $_->[0] } @{$_keywords->{$plugin}};
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

And in your application:

    package My::Webapp;
    
    use Dancer ':syntax';
    use Dancer::Plugin::LinkBlocker;

    block_links_from; # this is exported by the plugin

=head1 PLUGINS

You can extend Dancer by writing your own Plugin.

A plugin is a module that exports a bunch of symbols to the current namespace
(the caller will see all the symbols defined via C<register>).

Note that you have to C<use> the plugin wherever you want to use its symbols.
For instance, if you have Webapp::App1 and Webapp::App2, both loaded from your
main application, they both need to C<use FooPlugin> if they want to use the
symbols exported by C<FooPlugin>.

=head2 METHODS

=over 4

=item B<register>

Lets you define a keyword that will be exported by the plugin.

    register my_symbol_to_export => sub {
        # ... some code 
    };

=item B<register_plugin>

A Dancer plugin must end with this statement. This lets the plugin register all
the symbols define with C<register> as exported symbols (via the L<Exporter>
module).

A Dancer plugin inherits from Dancer::Plugin and Exporter transparently.

=item B<plugin_setting>

Configuration for plugin should be structured like this in the config.yml of
the application:

  plugins:
    plugin_name:
      key: value

If C<plugin_setting> is called inside a plugin, the appropriate configuration 
will be returned. The C<plugin_name> should be the name of the package, or, 
if the plugin name is under the B<Dancer::Plugin::> namespace (which is
recommended), the remaining part of the plugin name. 

Enclose the remaining part in quotes if it contains ::, e.g.
for B<Dancer::Plugin::Foo::Bar>, use:

  plugins:
    "Foo::Bar":
      key: value

=back

=head1 AUTHORS

This module has been written by Alexis Sukrieh and others.

=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.

=cut
