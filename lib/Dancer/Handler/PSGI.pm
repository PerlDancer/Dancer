package Dancer::Handler::PSGI;

use strict;
use warnings;
use Carp;
use base 'Dancer::Handler';

use Dancer::GetOpt;
use Dancer::Headers;
use Dancer::Config;
use Dancer::ModuleLoader;
use Dancer::SharedData;
use Dancer::Logger;

sub new {
    my $class = shift;

    croak "Plack::Request is needed by the PSGI handler"
      unless Dancer::ModuleLoader->load('Plack::Request');

    my $self = {};
    bless $self, $class;
    return $self;
}

sub dance {
    my $self = shift;

    my $app = sub {
        my $env = shift;
        $self->init_request_headers($env);
        my $request = Dancer::Request->new($env);
        $self->handle_request($request);
    };

    if (Dancer::Config::setting('plack_middlewares')) {
        my $middlewares = Dancer::Config::setting('plack_middlewares');
        croak "Plack::Builder is needed for middlewares support"
          unless Dancer::ModuleLoader->load('Plack::Builder');

        my $builder = Plack::Builder->new();
        for my $m (keys %$middlewares) {
            $builder->add_middleware($m, @{$middlewares->{$m}});
        }
        $app = $builder->to_app($app);
    }

    return $app;
}

sub init_request_headers {
    my ($self, $env) = @_;

    my $plack = Plack::Request->new($env);
    my $headers = Dancer::Headers->new(headers => $plack->headers);
    Dancer::SharedData->headers($headers);
}

1;
