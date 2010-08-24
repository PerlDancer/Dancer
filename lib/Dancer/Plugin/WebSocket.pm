package Dancer::Plugin::WebSocket;

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;

register websocket => \&websocket;

BEGIN {
    die "Plack is required for WebSocket support"
      unless Dancer::ModuleLoader->load('Plack::Builder');
}

sub websocket {
    my ($pattern, $code) = @_;

    my $compiled_route = sub {
        my $res = $code->();
        $res;
    };
    get $pattern => $compiled_route;
}

register_plugin;

1;
