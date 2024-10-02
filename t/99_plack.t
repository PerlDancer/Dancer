use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

{

    package Foo;

    use Dancer;

    get '/' => sub {
        return 'Hello World';
    };
}

# Pretend to have a version number while still in development
$Dancer::VERSION //= 0;

my $app = Dancer::Handler->psgi_app;
is( ref $app, 'CODE', 'Got app' );

test_psgi $app, sub {
    my $cb = shift;
    is( $cb->( GET '/' )->content, 'Hello World', 'root route' );
};

done_testing;
