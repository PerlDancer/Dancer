use strict;
use warnings;
use Test::More tests => 5, import => ['!pass'];

{
    use Dancer ':syntax';
    get '/foo/:key' => sub { params->{'key'} };

    get '/simple' => sub { 1 };
}

use Dancer::App;
my $reg = Dancer::App->current->registry;

ok($reg->is_new, "registry is new");
$reg->compile;

ok ((!$reg->is_new), "registry is compiled");

my $expected_regexp = '^\/foo\/([^\/]+)$' ;
is_deeply($reg->{_regexps}, {
    '/foo/:key' => [$expected_regexp, ['key'], 1 ],
    '/simple'   => ['^\/simple$', [], 0 ], 
    },
    "compiled registry is done, and looks good");

my ($regexp, $variables) = @{ $reg->get_regexp('/foo/:key') };
is $regexp, $expected_regexp, 'regexp is sent by get_regexp_from_route';
is_deeply $variables, [ 'key' ], "variables are sent by get_regexp_from_route";

