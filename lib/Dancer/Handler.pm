package Dancer::Handler;
our $AUTHORITY = 'cpan:SUKRIA';
# ABSTRACT: Dancer request handler
$Dancer::Handler::VERSION = '1.3202';
use strict;
use warnings;
use Carp;

use File::stat;
use HTTP::Headers;

use Dancer::Logger;
use Dancer::GetOpt;
use Dancer::SharedData;
use Dancer::Renderer;
use Dancer::Config 'setting';
use Dancer::ModuleLoader;
use Dancer::Exception qw(:all);
use Dancer::Factory::Hook;

use Encode;

Dancer::Factory::Hook->instance->install_hooks(
    qw/on_handler_exception/
);

# This is where we choose which application handler to return
sub get_handler {
    my $handler = 'Dancer::Handler::Standalone';

    # force PSGI is PLACK_ENV is set
    if ($ENV{'PLACK_ENV'}) {
        Dancer::Logger::core("PLACK_ENV is set (".$ENV{'PLACK_ENV'}.") forcing PSGI handler");
        setting('apphandler'  => 'PSGI');
    }

    # if Plack is detected or set by conf, use the PSGI handler
    if ( defined setting('apphandler') ) {
        $handler = 'Dancer::Handler::' . setting('apphandler');
    }

    # load the app handler
    my ($loaded, $error) = Dancer::ModuleLoader->load($handler);
    raise core_handler => "Unable to load app handler `$handler': $error" if $error;

    # OK, everything's fine, load the handler
    Dancer::Logger::core('loading ' . $handler . ' handler');
    return $handler->new;
}

# handle an incoming request, process it and return a response
sub handle_request {
    my ($self, $request) = @_;
    my $ip_addr = $request->remote_address || '-';

    Dancer::SharedData->reset_all( reset_vars => !$request->is_forward);

    Dancer::Logger::core("request: "
          . $request->method . " "
          . $request->path_info
          . " from $ip_addr");

    # save the request object
    Dancer::SharedData->request($request);

    # deserialize the request body if possible
    $request = Dancer::Serializer->process_request($request)
      if Dancer::App->current->setting('serializer');

    # read cookies from client

    Dancer::Cookies->init;

    Dancer::App->reload_apps if Dancer::Config::setting('auto_reload');

    render_request($request);
    return $self->render_response();
}

sub render_request {
    my $request = shift;
    my $action;
    $action = try {
        Dancer::Renderer->render_file
        || Dancer::Renderer->render_action
        || Dancer::Renderer->render_autopage
        || Dancer::Renderer->render_error(404);
    } continuation {
        # workflow exception (continuation)
        my ($continuation) = @_;
        $continuation->isa('Dancer::Continuation::Halted')
          or $continuation->rethrow();
        # special case for halted workflow continuation: still render the response
        Dancer::Serializer->process_response(Dancer::SharedData->response);
    } catch {
        my ($exception) = @_;
        Dancer::Factory::Hook->execute_hooks('on_handler_exception', $exception);
        Dancer::Logger::error(
            sprintf(
                'request to %s %s crashed: %s',
                $request->method, $request->path_info, $exception
            )
        );

        # use stringification, to get exception message in case of a
        # Dancer::Exception
        Dancer::Error->new(
          code    => 500,
          title   => "Runtime Error",
          message => "$exception",
          exception => $exception,
        )->render();
    };
    return $action;
}

sub psgi_app {
    my $self = shift;
    sub {
        my $env = shift;
        $self->init_request_headers($env);
        my $request = Dancer::Request->new(env => $env);
        $self->handle_request($request);
    };
}

sub init_request_headers {
    my ($self, $env) = @_;

    my $psgi_headers = HTTP::Headers->new(
        map {
            (my $field = $_) =~ s/^HTTPS?_//;
            ($field => $env->{$_});
          }
          grep {/^(?:HTTP|CONTENT|COOKIE)/i} keys %$env
    );
    Dancer::SharedData->headers($psgi_headers);
}

# render a PSGI-formatted response from a response built by
# handle_request()
sub render_response {
    my $self     = shift;
    my $response = Dancer::SharedData->response();

    my $content = $response->content;

    unless ( ref($content) eq 'GLOB' ) {
        my $charset = setting('charset');
        my $ctype   = $response->header('Content-Type');

        if ( $charset && $ctype && _is_text($ctype) ) {
            $content = Encode::encode( $charset, $content ) unless $response->_already_encoded;
            $response->header( 'Content-Type' => "$ctype; charset=$charset" )
              if $ctype !~ /$charset/;
        }
        if (!defined $response->header('Content-Length')) {
            use bytes; # turn off character semantics
            $response->header( 'Content-Length' => length($content) );
        }
        $content = [$content];
    }
    else {
        if ( !defined $response->header('Content-Length') ) {
            my $stat = stat $content;
            $response->header( 'Content-Length' => $stat->size );
        }
    }

    # drop content if request is HEAD
    $content = ['']
      if ( defined Dancer::SharedData->request
        && Dancer::SharedData->request->is_head() );

    # drop content AND content_length if response is 1xx or (2|3)04
    if ($response->status =~ (/^[23]04$/ )) {
        $content = [''];
        $response->header('Content-Length' => 0);
    }

    Dancer::Logger::core("response: " . $response->status);

    my $status  = $response->status();
    my $headers = $response->headers_to_array();

    # reverse streaming
    if ( ref $response->streamed and ref $response->streamed eq 'CODE' ) {
        return $response->streamed->(
            $status, $headers
        );
    }

    return [ $status, $headers, $content ];
}

sub _is_text {
    my ($content_type) = @_;
    return $content_type =~ /(\bx(?:ht)?ml\b|text|json|javascript)/;
}

# Fancy banner to print on startup
sub print_banner {
    if (setting('startup_info')) {
        my $env = setting('environment');
        print "== Entering the $env dance floor ...\n";
    }
}

sub dance { (shift)->start(@_) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Handler - Dancer request handler

=head1 VERSION

version 1.3202

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
