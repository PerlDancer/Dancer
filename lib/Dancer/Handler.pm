package Dancer::Handler;

use strict;
use warnings;

use Dancer::Logger;
use Dancer::GetOpt;
use Dancer::SharedData;
use Dancer::Renderer;
use Dancer::Config 'setting';

# supported application handlers
use Dancer::Handler::PSGI;
use Dancer::Handler::Standalone;

# This is where we choose which application handler to return
sub get_handler {
    if (setting('apphandler') eq 'PSGI') {
        return Dancer::Handler::PSGI->new;
    }
    else {
        return Dancer::Handler::Standalone->new;
    }
}

# handle an incoming request, process it and return a response
sub handle_request {
    my ($self, $request) = @_;
    Dancer::SharedData->request($request);

    # read cookies from client
    Dancer::Cookies->init;

    # if a serializer is set, and content is present in the body of the request,
    # deserialize it
    if ( setting('serializer') ) {
        if ( $request->{method} eq 'PUT' || $request->{method} eq 'POST' ) {
            my $rdata      = $request->{body};
            my $new_params = Dancer::Serializer->engine->deserialize($rdata);
            if ( keys %{ $request->{params} } ) {
                $request->{params}
                    = { %{ $request->{params} }, %$new_params };
            }
            else {
                $request->{params} = $new_params;
            }
        }
    }

    if (setting('auto_reload')) {
        eval "use Module::Refresh";
        if ($@) {
            Dancer::Logger->warning("auto_reload is set, "
                  . "but Module::Refresh is not installed");
        }
        else {
            my $orig_reg = Dancer::Route->registry;
            Dancer::Route->purge_all;
            Module::Refresh->refresh;
            my $new_reg = Dancer::Route->registry;
            Dancer::Route->merge_registry($orig_reg, $new_reg);
        }
    }

    my $response =
         Dancer::Renderer->render_file
      || Dancer::Renderer->render_action
      || Dancer::Renderer->render_error(404);

    Dancer::SharedData->reset_all();
    return $self->render_response($response);
}

# render a PSGI-formated response from a response built by
# handle_request()
sub render_response {
    my ($self, $response) = @_;

    my $content = $response->{content};

    # if a serializer is set, and the response content is a ref,
    # serialize it!
    if (setting('serializer')) {
        if (ref($content) && (ref($content) ne 'GLOB')) {
            $response->update_headers(
                'Content-Type' => Dancer::Serializer->engine->content_type);
            $content = Dancer::Serializer->engine->serialize($content);
        }
    }
    $content = [$content] unless (ref($content) eq 'GLOB');

    return [$response->{status}, $response->{headers}, $content];
}

# Fancy banner to print on startup
sub print_banner {
    if (setting('access_log')) {
        my $env = setting('environment');
        print "== Entering the $env dance floor ...\n";
    }
}

1;
