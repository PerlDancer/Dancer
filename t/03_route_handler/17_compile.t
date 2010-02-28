use strict;
use warnings;
use Test::More tests => 4, import => ['!pass'];

{
    use Dancer;
    get '/foo/:key' => sub { params->{'key'} };
}

use Dancer::Route;

is_deeply(Dancer::Route->compiled, { _state => 'NEW' },
    "compiled registry is uninitialized");

Dancer::Route->_compile_routes();

my $expected_regexp = '^\/foo\/([^\/]+)$' ;
is_deeply(Dancer::Route->compiled, { _state => 'DONE', 
    '/foo/:key' => [$expected_regexp, ['key'] ] },
    "compiled registry is done, and looks good");

my ($regexp, $variables) = @{ Dancer::Route::get_regexp_from_route('/foo/:key') };
is $regexp, $expected_regexp, 'regexp is sent by get_regexp_from_route';
is_deeply $variables, [ 'key' ], "variables are sent by get_regexp_from_route";

