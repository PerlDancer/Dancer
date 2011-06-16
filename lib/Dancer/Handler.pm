package Dancer::Handler;
# ABSTRACT: Dancer request's handler code
use strict;
use warnings;
use Carp 'croak';

use File::stat;
use HTTP::Headers;

use Dancer::Logger;
use Dancer::GetOpt;
use Dancer::SharedData;
use Dancer::Renderer;
use Dancer::Config 'setting';
use Dancer::ModuleLoader;

use Encode;

=func get_handler

This is where we choose which application handler to return given the
environment and application settings.

=cut
sub get_handler {
    my $handler = 'Dancer::Handler::Standalone';

    # force PSGI is PLACK_ENV is set
    if ($ENV{'PLACK_ENV'}) {
        Dancer::Logger::core("PLACK_ENV is set (".$ENV{'PLACK_ENV'}.") forcing PSGI handler");
        setting('apphandler'  => 'PSGI');
        setting('environment' => $ENV{'PLACK_ENV'});
    }

    # if Plack is detected or set by conf, use the PSGI handler
    if ( defined setting('apphandler') ) {
        $handler = 'Dancer::Handler::' . setting('apphandler');
    }

    # load the app handler
    my ($loaded, $error) = Dancer::ModuleLoader->load($handler);
    croak "Unable to load app handler `$handler': $error" if $error;

    # OK, everything's fine, load the handler
    Dancer::Logger::core('loading ' . $handler . ' handler');
    return $handler->new;
}

=method handle_request

Handle an incoming L<Dancer::Request>, process it, and return a
L<Dancer::Response>.

=cut
sub handle_request {
    my ($self, $request) = @_;
    my $ip_addr = $request->remote_address || '-';

    Dancer::SharedData->reset_all();

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

    if (Dancer::Config::setting('auto_reload')) {
        Dancer::App->reload_apps;
    }

    _render_request($request);
    return $self->render_response();
}

=method psgi_app ($env)

Returns a PSGI Application.

=cut
sub psgi_app {
    my $self = shift;
    sub {
        my $env = shift;
        $self->init_request_headers($env);
        my $request = Dancer::Request->new(env => $env);
        $self->handle_request($request);
    };
}

=method init_request_headers ($env)

Initializes L<HTTP::Headers> accordingly with the current environment.

=cut
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

=method render_response

Renders a PSGI-formated response from a response built by
handle_request()

=cut
sub render_response {
    my $self     = shift;
    my $response = Dancer::SharedData->response();

    my $content = $response->content;

    unless ( ref($content) eq 'GLOB' ) {
        my $charset = setting('charset');
        my $ctype   = $response->header('Content-Type');

        if ( $charset && $ctype && _is_text($ctype) ) {
            $content = Encode::encode( $charset, $content ) unless $response->already_encoded;
            $response->header( 'Content-Type' => "$ctype; charset=$charset" )
              if $ctype !~ /$charset/;
        }
        $response->header( 'Content-Length' => length($content) )
          if !defined $response->header('Content-Length');
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

    # drop content AND content_length if reponse is 1xx or (2|3)04
    if ($response->status =~ (/^[23]04$/ )) {
        $content = [''];
        $response->header('Content-Length' => 0);
    }

    Dancer::Logger::core("response: " . $response->status);

    my $status  = $response->status();
    my $headers = $response->headers_to_array();

    return [ $status, $headers, $content ];
}

=method dance

Starts the configured L<Dancer::Handler>

=cut
sub dance { (shift)->start(@_) }



# privates

sub _is_text {
    my ($content_type) = @_;
    return $content_type =~ /(text|json)/;
}

# This one is also used in Test.pm, but should be private
sub _render_request {
    my $request = shift;
    my $action;
    $action = eval {
        Dancer::Renderer->render_file
          || Dancer::Renderer->render_action
          || Dancer::Renderer->render_error(404);
    };
    if ($@) {
        Dancer::Logger::error(
            'request to ' . $request->path_info . " crashed: $@");

        Dancer::Error->new(
            code    => 500,
            title   => "Runtime Error",
            message => $@
        )->render();
    }
    return $action;
}


# Fancy banner to print on startup
sub _THIS_IS_NOT_BEING_USED_print_banner {
    if (setting('startup_info')) {
        my $env = setting('environment');
        print "== Entering the $env dance floor ...\n";
    }
}

1;
