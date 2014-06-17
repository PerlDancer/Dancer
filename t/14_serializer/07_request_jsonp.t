use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer ':tests';
use Dancer::Test;

BEGIN {
    plan skip_all => "need JSON"
      unless Dancer::ModuleLoader->load('JSON');

    plan tests => 2;
}

set 'serializer' => 'JSONP', 'show_errors' => 1;

get  '/'          => sub { { foo => 'bar' } };

my $res = dancer_response( GET => '/' , { params => { callback => 'func' } } );
is $res->header('Content-Type'), 'application/javascript';
like $res->content, qr/func\( \s* \{ \s* "foo" \s* : \s* "bar" \s* \} \s* \); /mix;

