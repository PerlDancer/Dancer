package Dancer::Handler::Debug;
# ABSTRACT: a debug handler for easy tracing
use strict;
use warnings;

use HTTP::Headers;
use HTTP::Server::Simple::PSGI;
use base 'Dancer::Object', 'Dancer::Handler', 'HTTP::Server::Simple::PSGI';

use Dancer::Config 'setting';
use Dancer::SharedData;

=method start

Starts the dummy debug server. Call it with the request that should be
debugged.

=cut
sub start {
    my ($self, $req) = @_;
    print STDERR ">> Dancer dummy debug server\n" if setting('startup_info');

    my $dancer = Dancer::Handler::Debug->new();
    my $psgi = sub {
        my $env = shift;
        my $req = Dancer::Request->new(env => $env);
        $dancer->handle_request($req);
    };
    $dancer->{psgi_app} = $psgi;
    $dancer->_run($req);
}

=method dance

Alias to the c<start> method.

=cut
sub dance { start(@_) }

# privates

sub _run {
    my ($self, $req) = @_;

    my ($method, $path, $query) = @ARGV;
    my $host    = "127.0.0.1";
    my $port    = "3000";

    my $env = {
        'HTTP_ACCEPT'     => '*/*',
        'HTTP_HOST'       => "$host:$port",
        'HTTP_USER_AGENT' => 'curl',
        'QUERY_STRING'    => $query,
        'REMOTE_ADDR'     => "$host:$port",
        'REMOTE_HOST'     => "$host:$port",
        'REQUEST_METHOD'  => $method,
        'REQUEST_URI'     => $path,
        'SERVER_NAME'     => $host,
        'SERVER_PORT'     => $port,
        'SERVER_PROTOCOL' => 'HTTP/1.1',
        'SERVER_SOFTWARE' => 'HTTP::Server::Simple/0.41',
        'SERVER_URL'      => "http://$host:$port/",
    };

    $req = Dancer::Request->new(env => $env);

    my $headers = HTTP::Headers->new(
        'User-Agent' => 'curl',
        'Host',   "$host:$port",
        'Accept', '*/*'
    );
    $req->headers($headers);

    # now simulate a PSGI response for the current request only
    my $res = eval { $self->{psgi_app}->($env) }
      || [500, ['Content-Type', 'text/plain'], ["Internal Server Error"]];

    $self->_handle_response($res);
    print "\n";

    return $res;
}


1;
__END__

=head1 SYNOPSIS

    # in bin/app.pl
    set apphandler => 'Debug';

    # then, run the app the following way
    perl -d bin/app.pl GET '/some/path/to/test' 'with=parameters&other=42'

=head1 DESCRIPTION

When developing a Dancer application, it can be useful to trace
precisely what happen when a query is processed. This handler is here
to provide the developer with a way to easily run the dancer
application with the Perl debugger.

This handler will process ony one query, based on the first argument
given on the command line ($ARGV[0]).

=cut


