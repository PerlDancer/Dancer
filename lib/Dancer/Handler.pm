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

sub init { 
    Dancer::GetOpt->process_args();
    Dancer::Config->load;
}

# This is where we choose which application handler to return
sub get_handler {
    if (setting('apphandler') eq 'PSGI') {
        return Dancer::Handler::PSGI->new;
    }
    else {
        return Dancer::Handler::Standalone->new;
    }
}

# virtual interface for any Dancer handler
# a dancer handler is class that can "run" Dancer apps.

sub dance { die "dance() must be implemented by handler" }
sub render_response { die "render_response() must be implemented by handler" }

# default handle_request method, should work for each handler
sub handle_request {
    my ($self, $cgi) = @_;
    Dancer::SharedData->cgi($cgi);
    
    # read cookies from client
    Dancer::Cookies->init;

    if (setting('auto_reload')) {
        eval "use Module::Refresh";
        if ($@) {
            Dancer::Logger->warning("auto_reload is set, ".
                "but Module::Refresh is not installed");
        }
        else {
            my $orig_reg = Dancer::Route->registry;
            Dancer::Route->purge_all;
            Module::Refresh->refresh;
            my $new_reg = Dancer::Route->registry;
            Dancer::Route->merge_registry($orig_reg, $new_reg); 
        }
    }

    my $response = Dancer::Renderer->render_file
        || Dancer::Renderer->render_action
        || Dancer::Renderer->render_error(404);
    
    return $self->render_response($response);
}

sub print_banner {
    if (setting('access_log')) {
        my $env = setting('environment');
        print "== Entering the $env dance floor ...\n";
    }
}

1;
