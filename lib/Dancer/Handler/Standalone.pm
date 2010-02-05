package Dancer::Handler::Standalone;

use strict;
use warnings;

use HTTP::Server::Simple::CGI;
use base 'Dancer::Handler', 'HTTP::Server::Simple::CGI';

use Dancer::HTTP;
use Dancer::GetOpt;
use Dancer::Config 'setting';
use Dancer::FileUtils qw(read_glob_content);

# in standalone mode, this method initializes the process
# and start an HTTP server
sub dance {
    Dancer::GetOpt->process_args();
    Dancer::Config->load;

    my $ipaddr = setting('server');
    my $port   = setting('port');

    if (setting('daemon')) {
        my $pid = Dancer::Handler::Standalone->new($port)->background();
        print ">> Dancer $pid listening on $port\n";
        return $pid;
    }
    else {
        print ">> Listening on http://$ipaddr:$port\n";
        Dancer::Handler::Standalone->new($port)->run();
    }
}

sub render_response {
    my ($self, $response) = @_;

    # status
    print Dancer::HTTP::status($response->{status});

    # headers
    my @headers = @{$response->{headers}};
    for (my $i = 0; $i < scalar(@headers); $i += 2) {
        my ($header, $value) = ($headers[$i], $headers[$i + 1]);
        print "${header}: $value\r\n";
    }
    print "\r\n";

    # content
    if (ref($response->{content}) eq 'GLOB') {
        print read_glob_content($response->{content});
    }

    # print content if any
    elsif (defined $response->{content}) {
        print $response->{content};
    }
}

1;
