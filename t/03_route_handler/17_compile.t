use strict;
use warnings;
use Test::More tests => 6, import => ['!pass'];

{
    use Dancer;
    get '/foo/:key' => sub { params->{'key'} };

    get '/simple' => sub { 1 };
}

use Dancer::Route::Builder;

ok(Dancer::Route::Builder->is_new, "registry is new");

is_deeply(Dancer::Route::Builder->registry, { _state => 'NEW' },
    "compiled registry is uninitialized");

Dancer::Route->compile_routes();

ok ((! Dancer::Route::Builder->is_new), "registry is compiled");

my $expected_regexp = '^\/foo\/([^\/]+)$' ;
is_deeply(Dancer::Route::Builder->registry, { _state => 'DONE', 
    '/foo/:key' => [$expected_regexp, ['key'], 1 ],
    '/simple'   => ['^\/simple$', [], 0 ], 
    },
    "compiled registry is done, and looks good");

my ($regexp, $variables) = @{ Dancer::Route::Builder->get_regexp('/foo/:key') };
is $regexp, $expected_regexp, 'regexp is sent by get_regexp_from_route';
is_deeply $variables, [ 'key' ], "variables are sent by get_regexp_from_route";

