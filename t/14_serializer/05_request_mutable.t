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

plan tests => 10;

setting serializer => 'mutable';

get  '/' => sub { { foo => 1 } };
post '/' => sub { request->params };
post '/echo' => sub { params };

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
            'Accept-Type'  => 'text/x-yaml'
        ]
    }
);

is_deeply(from_yaml($res->content), {foo => 42});
is $res->header('Content-Type'), 'text/x-yaml';

# Make sure to grok correct (de)serializer for body params
# when the Content-Type is as supported media type with additional
# parameters.
my $data = { bar => 4711 };
$res = dancer_response(
    POST => '/echo',
    {
        body => to_yaml($data), # make sure to stringify
        # Specifying this content_type is redundant but dancer_response
        # has a bug in that it does not take the Content-Type of the
        # headers before falling back to
        # application/x-www-form-urlencoded :(
        content_type => 'text/x-yaml; charset=utf-8',
        headers => [
            'Content-Type' => 'text/x-yaml; charset=utf-8',
        ]
    }
);
is_deeply( from_yaml( $res->content ), $data );
is $res->header('Content-Type'), 'text/x-yaml; charset=utf-8';

# We were incorrectly using 'Content-Type' also for responses although
# the user told us in 'Accept' to use a different format.
$res = dancer_response(
    POST => '/echo',
    {
        body => to_json($data), # make sure to stringify
        # Specifying this content_type is redundant but dancer_response
        # has a bug in that it does not take the Content-Type of the
        # headers before falling back to
        # application/x-www-form-urlencoded :(
        content_type => 'application/json; charset=utf-8',
        headers => [
            'Content-Type' => 'application/json; charset=utf-8',
            'Accept'       => 'text/x-yaml; charset=utf-8',
        ]
    }
);
is_deeply( from_yaml( $res->content ), $data );
is $res->header('Content-Type'), 'text/x-yaml; charset=utf-8';

