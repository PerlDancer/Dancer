package Dancer::Handler::PSGI;

use strict;
use warnings;
use base 'Dancer::Handler';

use Dancer::GetOpt;
use Dancer::Headers;
use Dancer::Config;
use Dancer::ModuleLoader;
use Dancer::SharedData;

sub new {
    my $class = shift;

    die "Plack::Request is needed by the PSGI handler"
        unless Dancer::ModuleLoader->load('Plack::Request');

    my $self  = {};
    bless $self, $class;
    Dancer::Route->init();
    return $self;
}

sub dance { process(@_) }

sub process {
    my ($self, $request) = @_;

    my $plack = Plack::Request->new($request->env);
    my $headers = Dancer::Headers->new(headers => $plack->headers);
    Dancer::SharedData->headers($headers);
    $request->_build_headers();

    $self->handle_request($request);
}

1;
