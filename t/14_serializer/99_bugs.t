use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer ':tests';
use Dancer::Test;
use HTTP::Request;

plan tests => 3;

# issue 57829
{
    skip 'JSON is needed to run this test', 2
      unless Dancer::ModuleLoader->load('JSON');

    setting( 'serializer' => 'JSON' );
    get '/' => sub { header 'X-Test' => 'ok'; { body => 'ok' } };

    my $res = dancer_response( GET => '/' );
    is $res->header('Content-Type'), 'application/json';
    is $res->header('X-Test'), 'ok';
}

# issue gh-106
{
    skip 'JSON is needed to run this test', 1
      unless Dancer::ModuleLoader->load('JSON');

    setting( 'serializer' => 'JSON' );
    setting engines => { JSON => { allow_blessed => 1, convert_blessed => 1 } };

    get '/blessed' => sub {
       my $r = HTTP::Request->new( GET => 'http://localhost' );
        { request => $r };
    };

    my $res = dancer_response( GET => '/blessed', {headers => ['Content-Type' => 'application/json']});
    is_deeply( from_json( $res->content ), { request => undef } );
}

# issue gh-299
{
    skip 'JSON is needed to run this test', 1
      unless Dancer::ModuleLoader->load('JSON');
}
