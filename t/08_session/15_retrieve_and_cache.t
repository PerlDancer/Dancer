use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 6;

{
    package MyApp;

    use Dancer;

    set session => 'VerySimple';

    get '/' => sub {
        session 'x' => 'blah';

        return join '',  session( 'x' ), session( 'x' );
    };

    get '/retrieve' => sub {
        return join '', map { session($_) }  ('x')x3;
    };

}

use Dancer::Test;

response_content_like '/' => qr/blahblah/;

is $::retrieve => undef, 'only creation, no retrieve';

response_content_like '/retrieve' => qr/(?:blah){3}/;

is $::retrieve => 1, 'only once';

response_content_like '/' => qr/blahblah/;

is $::retrieve => 2, 'only retrieve';


