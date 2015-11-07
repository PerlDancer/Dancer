package Dancer::Plugin::Ajax;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: a plugin for adding Ajax route handlers
$Dancer::Plugin::Ajax::VERSION = '1.3202';
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Exception ':all';
use Dancer::Plugin;

register 'ajax' => \&ajax;

hook before => sub {
    if (request->is_ajax) {
        content_type( plugin_setting->{content_type} || 'text/xml' );
    }
};

sub ajax {
    my ($pattern, @rest) = @_;

    my $code;
    for my $e (@rest) { $code = $e if (ref($e) eq 'CODE') }

    my $ajax_route = sub {
        # must be an XMLHttpRequest
        if (not request->is_ajax) {
            pass and return 0;
        }

        # disable layout
        my $layout = setting('layout');
        setting('layout' => undef);
        my $response = try {
            $code->();
        } catch {
            my $e = $_;
            setting('layout' => $layout);
            die $e;
        };
        setting('layout' => $layout);
        return $response;
    };

    # rebuild the @rest array with the compiled route handler
    my @compiled_rest;
    for my $e (@rest) {
        if (ref($e) eq 'CODE') {
            push @compiled_rest, {ajax => 1}, $ajax_route;
        }
        else {
            push @compiled_rest, {ajax => 1}, $e;
        }
    }

    any ['get', 'post'] => $pattern, @compiled_rest;
}

register_plugin;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Plugin::Ajax - a plugin for adding Ajax route handlers

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

    package MyWebApp;

    use Dancer;
    use Dancer::Plugin::Ajax;

    ajax '/check_for_update' => sub {
        # ... some Ajax code
    };

    dance;

=head1 DESCRIPTION

The C<ajax> keyword which is exported by this plugin allow you to define a route
handler optimized for Ajax queries.

The route handler code will be compiled to behave like the following:

=over 4

=item *

Pass if the request header X-Requested-With doesnt equal XMLHttpRequest

=item *

Disable the layout

=item *

The action built matches POST / GET requests.

=back

=head1 CONFIGURATION

By default the plugin will use a content-type of 'text/xml' but this can be overwritten
with plugin setting 'content_type'.

Here is example to use JSON:

  plugins:
    'Ajax':
      content_type: 'application/json'

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@sukria.net>

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
