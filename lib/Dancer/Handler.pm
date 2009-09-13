package Dancer::Handler;

use strict;
use warnings;

use Dancer::SharedData;
use Dancer::Renderer;
use Dancer::Handler::Plack;
use Dancer::Handler::Standalone;

# This is where we chose which application handler to return
sub get_handler {
    # TODO
    return Dancer::Handler::Plack->new;
}

# virtual interface for any Dancer handler
# a dancer handler is class that can "run" Dancer apps.

sub dance { die "must be implemented by handler" }
sub run   { die "must be implemented by handler" }

# default handle_request method, should work for each handler
sub handle_request {
    my ($self, $cgi) = @_;
    Dancer::SharedData->cgi($cgi);
    return Dancer::Renderer->render_file
        || Dancer::Renderer->render_action
        || Dancer::Renderer->render_error;
}

sub new {
    my $class = shift;
    bless {}, $class;
}

1;
