package Dancer::Handler::PSGI;

use strict;
use warnings;
use Carp;
use base 'Dancer::Handler';

use Dancer::Deprecation;
use Dancer::GetOpt;
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
}

sub start {
    my $self = shift;
    my $app  = $self->psgi_app();

    foreach my $setting (qw/plack_middlewares plack_middlewares_map/) {
        if (Dancer::Config::setting($setting)) {
            my $method = 'apply_'.$setting;
            $app = $self->$method($app);
        }
    }

    return $app;
}

sub apply_plack_middlewares_map {
    my ($self, $app) = @_;

    my $mw_map = Dancer::Config::setting('plack_middlewares_map');

    foreach my $req (qw(Plack::App::URLMap Plack::Builder)) {
        croak "$req is needed to use apply_plack_middlewares_map"
          unless Dancer::ModuleLoader->load($req);
    }

    my $urlmap = Plack::App::URLMap->new;

    while ( my ( $path, $mw ) = each %$mw_map ) {
        my $builder = Plack::Builder->new();
        $builder->add_middleware(@$_) for @$mw;
        $urlmap->map( $path => $builder->to_app($app) );
    }

    $urlmap->map('/' => $app) unless $mw_map->{'/'};
    return $urlmap->to_app;
}

sub apply_plack_middlewares {
    my ($self, $app) = @_;

    my $middlewares = Dancer::Config::setting('plack_middlewares');

    croak "Plack::Builder is needed for middlewares support"
      unless Dancer::ModuleLoader->load('Plack::Builder');

    ref $middlewares eq "ARRAY"
      or croak "'plack_middlewares' setting must be an ArrayRef";

    my $builder = Plack::Builder->new();

    for my $mw (@$middlewares) {
        Dancer::Logger::core "add middleware " . $mw->[0];
        $builder->add_middleware(@$mw)
    }

    return $builder->to_app($app);
}

sub init_request_headers {
    my ($self, $env) = @_;
    my $plack = Plack::Request->new($env);
    Dancer::SharedData->headers($plack->headers);
}

1;
__END__

=pod

=head1 NAME

Dancer::Handler::PSGI - a PSGI handler for Dancer applications

=head1 DESCRIPTION

This handler allows Dancer applications to run as part of PSGI stacks. Dancer
will automatically determine when running in a PSGI environment and enable this
handler, such that calling C<dance> will return a valid PSGI application.

You may enable Plack middleware in your configuration file under the
C<plack_middlewares> key. See L<Dancer::Cookbook> for more information.

Note that you must have L<Plack> installed for this handler to work.

=head1 USAGE
    # in bin/app.pl
    set apphandler => 'Debug';

    # then, run the app the following way
    perl -d bin/app.pl GET '/some/path/to/test' 'with=parameters&other=42'

=head1 AUTHORS

Dancer contributors
