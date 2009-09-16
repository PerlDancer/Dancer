package Dancer::Handler::PSGI;

use strict;
use warnings;
use base 'Dancer::Handler';

use Dancer::GetOpt;
use Dancer::Config;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub dance {
    Dancer::GetOpt->process_args();
    Dancer::Config->load;
}

sub run {
    my ($self, $class, $cgi) = @_;
    $self->handle_request($cgi);
}

sub render_response {
    my ($self, $response) = @_;
    
    my $content = $response->{content};
    $content = [ $content ] unless (ref($content) eq 'GLOB');

    return [ 
        $response->{status},
        [ %{ $response->{headers} } ],
        $content
    ];
}

1;
