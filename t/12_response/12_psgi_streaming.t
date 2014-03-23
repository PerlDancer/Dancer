package main;
use strict;
use warnings;
use Test::More tests => 2, import => ['!pass'];
use Dancer::Test;

{
    use Dancer;
    set environment => 'psgi.streaming';    # it is required in a real-world app
                                            # but here it makes no difference
    get '/psgi' => sub {
        return request->env->{'psgi.streaming'} ? 'YES' : 'NO';
        sub {
            # implementation is irrelevant
        }
    };
}

note "Testing PSGI-streaming response";
my $req = [ GET => '/psgi' ];
route_exists $req;
my $res = dancer_response @$req;
is(ref($res->content), 'CODE', 'reponse contains coderef');

1;

