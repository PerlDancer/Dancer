package Dancer::Plugin::Ajax;

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;

our $VERSION = '1.00';

register 'ajax' => \&ajax;

hook before => sub {
    if (request->is_ajax) {
        content_type('text/xml');
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
        my $response = $code->();
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

=head1 NAME

Dancer::Plugin::Ajax - a plugin for adding Ajax route handlers

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

The action built is a POST request.

=back

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@sukria.net>

=cut
