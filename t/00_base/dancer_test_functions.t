use strict;
use warnings;

use Test::More;

plan tests => 29;

use Dancer qw/ :syntax :tests /;
use Dancer::Test;

# verify that all test helper functions are behaving the way
# we want

our $route = '/marco';

get $route => sub { 'polo' };

my $resp = dancer_response GET => '/marco';

my @req = ( [ GET => $route ], $route, $resp );

test_helping_functions( $_ ) for @req;

sub test_helping_functions {
    my $req = shift;

    response_exists $req;
    response_status_is $req => 200;
    response_status_isnt $req => 613;

    response_content_is $req => 'polo';
    response_content_isnt $req => 'stuff';
    response_content_is_deeply $req => 'polo';
    response_content_like $req => qr/.ol/;
    response_content_unlike $req => qr/\d/;
    response_headers_are_deeply $req => [ qw# Content-Type text/html #];
}

TODO: {
    local $TODO = 'suspicious';

    response_doesnt_exist [ GET => '/nonexistant' ];
    response_doesnt_exist '/nonexistant';
}


