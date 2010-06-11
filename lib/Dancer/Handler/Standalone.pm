package Dancer::Handler::Standalone;

use strict;
use warnings;

use HTTP::Server::Simple::PSGI;
use base 'Dancer::Handler', 'HTTP::Server::Simple::PSGI';

use Dancer::HTTP;
use Dancer::GetOpt;
use Dancer::Config 'setting';
use Dancer::Headers;
use Dancer::FileUtils qw(read_glob_content);
use Dancer::SharedData;

# we have to subclass headers, from HTTP::Server::Simple in order to catch them
sub headers {
    my ($self, $headers) = @_;
    
    # first, save the headers
    my $dh = Dancer::Headers->new(headers => $headers);
    Dancer::SharedData->headers($dh);
    
    # then, let the SUPER method do its job
    $self->SUPER::headers($headers);
}

# in standalone mode, this method initializes the process
# and start an HTTP server
sub start {
    my $ipaddr = setting('server');
    my $port   = setting('port');
    my $dancer = Dancer::Handler::Standalone->new($port);
    $dancer->host($ipaddr);

    my $app = sub {
        my $env = shift;
        my $req = Dancer::Request->new($env);
        $dancer->handle_request($req);
    };

    Dancer::Route->init();
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

sub dance { start(@_) }
1;
