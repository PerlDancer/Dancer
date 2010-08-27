package Dancer::Handler::Debug;

use strict;
use warnings;

use HTTP::Server::Simple::PSGI;
use base 'Dancer::Handler', 'HTTP::Server::Simple::PSGI';

use Dancer::Config 'setting';
use Dancer::Headers;
use Dancer::SharedData;

sub headers {
    my ($self, $headers) = @_;
    my $dh = Dancer::Headers->new(headers => $headers);
    Dancer::SharedData->headers($dh);
}

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;
    return $self;
}

sub run {
    my ($self, $req) = @_;

    my $method = $req->method;
    my $path   = $req->path;

    my $host    = "127.0.0.1";
    my $port    = "3000";
    my @headers = (
        'User-Agent' => 'curl',
        'Host',   "$host:$port",
        'Accept', '*/*'
    );
    $self->headers(\@headers);

    my $env = {
        'HTTP_ACCEPT'     => '*/*',
        'HTTP_HOST'       => "$host:$port",
        'HTTP_USER_AGENT' => 'curl',
        'QUERY_STRING'    => '',
        'REMOTE_ADDR'     => "$host:$port",
        'REMOTE_HOST'     => "$host:$port",
        'REQUEST_METHOD'  => $method,
        'REQUEST_URI'     => $path,
        'SERVER_NAME'     => $host,
        'SERVER_PORT'     => $port,
        'SERVER_PROTOCOL' => 'HTTP/1.1',
        'SERVER_SOFTWARE' => 'HTTP::Server::Simple/0.41',
        'SERVER_URL'      => 'http://$host:$port/',
    };

    for my $arg (@ARGV) {
        my ($k, $v) = split(/=/, $arg, 2);
        $env->{$k} = $v;
    }

    my $res = eval { $self->{psgi_app}->($env) }
      || [500, ['Content-Type', 'text/plain'], ["Internal Server Error"]];
    $self->_handle_response($res);
    print "\n";
    return $self;
}

sub start {
    my ($self, $req) = @_;
    $req ||= Dancer::SharedData->request;

    my $ipaddr = setting('server');
    my $port   = setting('port');
    my $dancer = Dancer::Handler::Debug->new($port);
    $dancer->host($ipaddr);

    my $app = sub {
        my $env = shift;
        my $req = Dancer::Request->new($env);
        $dancer->handle_request($req);
    };

    $dancer->app($app);

    print STDERR ">> Dancer dummy debug server\n" if setting('access_log');
    $dancer->run($req);
}

sub dance { start(@_) }
1;
