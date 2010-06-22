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

use Encode;

# This is where we choose which application handler to return
sub get_handler {
    if (setting('apphandler') eq 'PSGI') {
        Dancer::Logger::core('loading PSGI handler');
        return Dancer::Handler::PSGI->new;
    }
    else {
        Dancer::Logger::core('loading Standalone handler');
        return Dancer::Handler::Standalone->new;
    }
}

# handle an incoming request, process it and return a response
sub handle_request {
    my ($self, $request) = @_;
    my $remote = $request->remote_address || '-';

    Dancer::SharedData->reset_timer;
    Dancer::Logger::core(
        "request: ".$request->method." ".$request->path 
        . " from " . $remote
    );

    # deserialize the request body if possible
    $request = Dancer::Serializer->process_request($request) if setting('serializer');

    # save the request object
    Dancer::SharedData->request($request);

    # read cookies from client
    Dancer::Cookies->init;

    # TODO : move that elsewhere
    if (setting('auto_reload')) {
        if (Dancer::ModuleLoader->load('Module::Refresh')) {
            my $orig_reg = Dancer::Route->registry;
            Dancer::Route->purge_all;
            Module::Refresh->refresh;
            my $new_reg = Dancer::Route->registry;
            Dancer::Route->merge_registry($orig_reg, $new_reg);
        }
        else {
            warn "Module::Refresh is not installed, " . 
                "install this module or unset 'auto_reload' in your config file";
        }
    }

    my $response;
    eval {
      $response = Dancer::Renderer->render_file
      || Dancer::Renderer->render_action
      || Dancer::Renderer->render_error(404)
    };
    if ($@) {
        my $error = Dancer::Error->new(
            code => 500,
            title => "Runtime Error",
            message => $@);
        $response = $error->render;
    }
    return $self->render_response($response);
}

# render a PSGI-formated response from a response built by
# handle_request()
sub render_response {
    my ($self, $response) = @_;

    my $content = $response->{content};
    unless (ref($content) eq 'GLOB') {
        my $charset = setting('charset');
        my $ctype = $response->{content_type};
        if ($charset && $ctype =~ /^text\// && $ctype !~ /charset=/ && utf8::is_utf8($content)) {
            $content = Encode::encode($charset, $content);
            $response->update_headers('Content-Type' => "$ctype; charset=$charset");
        }

        $content = [ $content ];
    }

    Dancer::Logger::core("response: ".$response->{status});
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
