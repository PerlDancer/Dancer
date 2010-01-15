package Dancer::Handler::PSGI;

use strict;
use warnings;
use base 'Dancer::Handler';

use Dancer::GetOpt;
use Dancer::Config;
use Dancer::SharedData;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub dance {
    my ($self, $request) = @_;
    Dancer::SharedData->request($request);
    $self->handle_request($request);
}

sub render_response {
    my ($self, $response) = @_;
    
    my $content = $response->{content};
    $content = [ $content ] unless (ref($content) eq 'GLOB');

    return [ 
        $response->{status},
        $response->{headers},
        $content
    ];
}

1;
