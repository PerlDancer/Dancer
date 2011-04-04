use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer ':tests';
use Dancer::Test;

BEGIN {
    plan skip_all => 'YAML is needed to run this test'
      unless Dancer::ModuleLoader->load('YAML');
    plan skip_all => 'JSON is needed to run this test'
      unless Dancer::ModuleLoader->load('JSON');
}

plan tests => 6;

setting(serializer => 'mutable');

get '/' => sub { { foo => 1 } };
post '/' => sub { request->params };

for my $ct (qw/Accept Accept-Type/) {
    my $res = dancer_response(
        GET => '/',
        {
            headers => [ $ct => 'application/json' ]
        }
    );
    is_deeply( from_json( $res->content ), { foo => 1 } );
    is $res->header('Content-Type'), 'application/json';
}

my $res = dancer_response(
    POST => '/',
    {
        params  => { foo => 42 },
        headers => [
            'Content-Type' => 'text/x-yaml',
            'Accept-Type'  => 'application/json'
        ]
    }
);

is_deeply(from_yaml($res->content), {foo => 42});
is $res->header('Content-Type'), 'text/x-yaml';
