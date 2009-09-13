package Dancer::Handler::PSGI;

use strict;
use warnings;
use base 'Dancer::Handler';

use Dancer::GetOpt;
use Dancer::Config;

sub dance {
    Dancer::GetOpt->process_args();
    Dancer::Config->load;
}

sub run {
    my ($self, $class, $cgi) = @_;
    $self->handle_request($cgi);
}

1;
