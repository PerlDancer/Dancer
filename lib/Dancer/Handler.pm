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

    # deserialize the request body if possible
    $request = Dancer::Serializer->process_request($request) if setting('serializer');

    # save the request object
    Dancer::SharedData->request($request);

    # read cookies from client
    Dancer::Cookies->init;

    # TODO : move that elsewhere
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

    return $self->render_response($response);
}

# render a PSGI-formated response from a response built by
# handle_request()
sub render_response {
    my ($self, $response) = @_;

    # serializing magick occurs here! (only if needed)
    $response = Dancer::Serializer->process_response($response)
        if setting('serializer');

    my $content = $response->{content};
    $content = [$content] unless (ref($content) eq 'GLOB');

    Dancer::SharedData->reset_all();

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
