package Dancer::Handler::PSGI;

use strict;
use warnings;
use base 'Dancer::Handler';

use Dancer::GetOpt;
use Dancer::Headers;
use Dancer::Config;
use Dancer::ModuleLoader;
use Dancer::SharedData;
use Dancer::Logger;

sub new {
    my $class = shift;

    die "Plack::Request is needed by the PSGI handler"
      unless Dancer::ModuleLoader->load('Plack::Request');

    my $self = {};
    bless $self, $class;
    return $self;
}

sub dance {
    my $self = shift;

    my $app = sub {
        my $env     = shift;
        my $request = Dancer::Request->new($env);
        $self->init_request_headers($request);
        $self->handle_request($request);
    };

    if (Dancer::Config::setting('plack_middlewares')) {
        my $middlewares = Dancer::Config::setting('plack_middlewares');
        die "Plack::Builder is needed for middlewares support"
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
    my ($self, $request) = @_;

    my $plack = Plack::Request->new($request->env);
    my $headers = Dancer::Headers->new(headers => $plack->headers);
    Dancer::SharedData->headers($headers);
    $request->_build_headers();
}

1;
