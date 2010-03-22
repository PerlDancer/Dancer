package Dancer::Handler::PSGI;

use strict;
use warnings;
use base 'Dancer::Handler';

use Dancer::GetOpt;
use Dancer::Config;
use Dancer::SharedData;

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    Dancer::Route->init();
    return $self;
}

sub dance {
    my $self = shift;
    return sub {
        my $env = shift;
        my $request = Dancer::Request->new($env);
        $self->handle_request($request);
    };
}

sub process {
    my ($self, $request) = @_;
    $self->handle_request($request);
}

1;
