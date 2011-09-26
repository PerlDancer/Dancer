use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer ':tests';
use Dancer::Test;
use HTTP::Request;

plan tests => 13;

# issue 57829
SKIP: {
    skip 'JSON is needed to run this test', 2
      unless Dancer::ModuleLoader->load('JSON');

    setting( 'serializer' => 'JSON' );
    get '/' => sub { header 'X-Test' => 'ok'; { body => 'ok' } };

    my $res = dancer_response( GET => '/' );
    is $res->header('Content-Type'), 'application/json';
    is $res->header('X-Test'), 'ok';
}

# issue gh-106
SKIP: {
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
SKIP: {
    skip 'JSON is needed to run this test', 5
      unless Dancer::ModuleLoader->load('JSON');

    get '/hash' => sub {{a => 1, b => 2, c => 3}};

    foreach my $method (qw/HEAD GET/){
        my $res = dancer_response($method => '/hash');
        is $res->status, 200;
        is $res->header('Content-Type'), 'application/json';
    }

    my $res = dancer_response(HEAD => '/hash');
    ok !$res->content;
}

# RT #57805
# https://rt.cpan.org/Ticket/Display.html?id=57805
#
# Serializer issue: params hash not populated when the Content-Type is a
# supported media type with additional parameters
SKIP: {
    skip 'JSON is needed to run this test', 3
      unless Dancer::ModuleLoader->load('JSON');

    post '/test' => sub {
        return { test_value => params->{test_value} };
    };

    my $data = { foo => 42 };

    for my $ct ( 'application/json', 'APPLICATION/JSON',
        'application/json; charset=UTF-8' )
    {
        my $res = dancer_response(
            POST => '/test',
            {
                body    => to_json(         { test_value => $data } ),
                headers => [ 'Content-Type' => $ct ]
            }
        );
        is_deeply(
            from_json( $res->content ),
            { test_value => $data },
            "correctly deserialized when Content-Type is set to '$ct'"
        );
    }
}

# show errors
SKIP: {
    skip 'JSON is needed to run this test', 2
        unless Dancer::ModuleLoader->load('JSON');

    set environment => 'production';

    get '/with_errors' => sub {
        setting show_errors => 1;
        # bam!
        UnknownPackage->method();
    };

    get '/without_errors' => sub {
        setting show_errors => 0;
        # bam!
        UnknownPackage->method();
    };

    my $res = dancer_response(GET => '/with_errors');
    like($res->content, qr{"error":"Can't locate object method \\"method\\" via package \\"UnknownPackage\\"});

    $res = dancer_response(GET => '/without_errors');
    like($res->content, qr{An internal error occured});
}
