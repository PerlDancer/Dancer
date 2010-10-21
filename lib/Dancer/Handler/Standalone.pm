package Dancer::Handler::Standalone;

use strict;
use warnings;

use HTTP::Headers;
use HTTP::Server::Simple::PSGI;
use base 'Dancer::Handler', 'HTTP::Server::Simple::PSGI';

use Dancer::HTTP;
use Dancer::GetOpt;
use Dancer::Config 'setting';
use Dancer::Headers;
use Dancer::FileUtils qw(read_glob_content);
use Dancer::SharedData;

# in standalone mode, this method initializes the process
# and start an HTTP server
sub start {
    my $self = shift;

    my $ipaddr = setting('server');
    my $port   = setting('port');
    my $dancer = Dancer::Handler::Standalone->new($port);
    $dancer->host($ipaddr);

    my $app = $self->psgi_app();

    $dancer->app($app);

    if (setting('daemon')) {
        my $pid = $dancer->background();
        print STDERR
          ">> Dancer server $pid listening on http://$ipaddr:$port\n"
          if setting('access_log');
        return $pid;
    }
    else {
        print STDERR ">> Dancer server $$ listening on http://$ipaddr:$port\n"
          if setting('access_log');
        $dancer->run();
    }
}

sub init_request_headers {
    my ($self, $env) = @_;

    my $psgi_headers = HTTP::Headers->new(
        map {
            (my $field = $_) =~ s/^HTTPS?_//;
            ($field => $env->{$_});
          }
          grep {/^(?:HTTP|CONTENT|COOKIE)/i} keys %$env
    );
    my $headers = Dancer::Headers->new(headers => $psgi_headers);
    Dancer::SharedData->headers($headers);
}

1;
