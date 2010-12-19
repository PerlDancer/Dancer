package Dancer::Handler;

use strict;
use warnings;
use Carp 'croak';

use HTTP::Headers;

use Dancer::Logger;
use Dancer::GetOpt;
use Dancer::SharedData;
use Dancer::Renderer;
use Dancer::Config 'setting';
use Dancer::ModuleLoader;

use Encode;

# This is where we choose which application handler to return
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

# handle an incoming request, process it and return a response
sub handle_request {
    my ($self, $request) = @_;
    my $ip_addr = $request->remote_address || '-';

    Dancer::SharedData->reset_timer;
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

    my $response;
    eval {
             $response = Dancer::Renderer->render_file
          || Dancer::Renderer->render_action
          || Dancer::Renderer->render_error(404);
    };
    if ($@) {
        Dancer::Logger::core(
            'request to ' . $request->path_info . " crashed: $@");

        my $error = Dancer::Error->new(
            code    => 500,
            title   => "Runtime Error",
            message => $@
        );
        $response = $error->render;
    }
    return $self->render_response($response);
}

sub psgi_app {
    my $self = shift;
    sub {
        my $env = shift;
        $self->init_request_headers($env);
        my $request = Dancer::Request->new($env);
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

# render a PSGI-formated response from a response built by
# handle_request()
sub render_response {
    my ($self, $response) = @_;

    my $content = $response->{content};
    unless (ref($content) eq 'GLOB') {

        # when the request is considered as ajax,
        # we set the content type to text/xml
        if (   Dancer::SharedData->request
            && Dancer::SharedData->request->is_ajax)
        {
            $response->header(
                'Content-Type' => 'text/xml; charset=UTF-8');
        }

        my $charset = setting('charset');
        my $ctype   = $response->header('Content-Type');

        if ($charset && $ctype && _is_text($ctype)) {
            $content = Encode::encode($charset, $content);
            $response->header('Content-Type' => "$ctype; charset=$charset")
              if $ctype !~ /$charset/;
        }
        $content = [$content];
    }

    Dancer::Logger::core("response: " . $response->{status});
    Dancer::SharedData->reset_all();
    return [$response->{status}, $response->headers_to_array, $content];
}

sub _is_text {
    my ($content_type) = @_;
    return $content_type =~ /(text|json)/;
}

# Fancy banner to print on startup
sub print_banner {
    if (setting('access_log')) {
        my $env = setting('environment');
        print "== Entering the $env dance floor ...\n";
    }
}

sub dance { (shift)->start(@_) }

1;
