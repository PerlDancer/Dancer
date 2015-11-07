package Dancer::Plugin;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: helper for writing Dancer plugins
$Dancer::Plugin::VERSION = '1.3202';
use strict;
use warnings;
use Carp;

use base 'Exporter';
use Dancer::Config 'setting';
use Dancer::Hook;
use Dancer::Factory::Hook;
use Dancer::Exception qw(:all);

use base 'Exporter';
use vars qw(@EXPORT);

@EXPORT = qw(
  add_hook
  register
  register_plugin
  plugin_setting
  register_hook
  execute_hooks
  execute_hook
  plugin_args
);

sub register($&);

my $_keywords = {};

sub add_hook { Dancer::Hook->new(@_) }

sub plugin_args { (undef, @_) }

sub plugin_setting {
    my $plugin_orig_name = caller();
    (my $plugin_name = $plugin_orig_name) =~ s/Dancer::Plugin:://;

    return setting('plugins')->{$plugin_name} ||= {};
}

sub register_hook {
    Dancer::Factory::Hook->instance->install_hooks(@_);
}

sub execute_hooks {
    Dancer::Deprecation->deprecated(reason => "use 'execute_hook'",
                                    version => '1.3098',
                                    fatal => 0);
    Dancer::Factory::Hook->instance->execute_hooks(@_);
}

sub execute_hook {
    Dancer::Factory::Hook->instance->execute_hooks(@_);
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
        @{"${plugin}::ISA"} = ('Dancer::Plugin', @{"${plugin}::ISA"});
        # this works because Dancer::Plugin already ISA Exporter
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

=encoding UTF-8

=head1 NAME

Dancer::Plugin - helper for writing Dancer plugins

=head1 VERSION

version 1.3202

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

=head1 DESCRIPTION

Create plugins for Dancer

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

=item B<register_hook>

Allows a plugin to declare a list of supported hooks. Any hook declared like so
can be executed by the plugin with C<execute_hooks>.

    register_hook 'foo'; 
    register_hook 'foo', 'bar', 'baz'; 

=item B<execute_hooks>

Allows a plugin to execute the hooks attached at the given position

    execute_hooks 'some_hook';

The hook must have been registered by the plugin first, with C<register_hook>.

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

=item B<plugin_args>

To easy migration and interoperability between Dancer 1 and Dancer 2
you can use this method to obtain the arguments or parameters passed
to a plugin-defined keyword. Although not relevant for Dancer 1 only,
or Dancer 2 only, plugins, it is useful for universal plugins.

  register foo => sub {
     my ($self, @args) = plugin_args(@_);
     ...
  }

Note that Dancer 1 will return undef as the object reference.

=back

=head1 AUTHORS

This module has been written by Alexis Sukrieh and others.

=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
