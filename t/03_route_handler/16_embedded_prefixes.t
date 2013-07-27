use strict;
use warnings;

use Test::More tests => 10;

use Dancer ':tests';
use Dancer::Test;

prefix '/a' => sub {
    prefix '/1' => sub {
        get '/A' => sub { '/a/1/A' };
    };
};
prefix '/b' => sub {
    prefix '/1' => sub {
        get '/A' => sub { '/b/1/A' };
    };
    prefix '/2' => sub {
        get '/A' => sub { '/b/2/A' };
        get '/B' => sub { '/b/2/B' };
    };
};
prefix '/c' => sub {
    prefix '/1' => sub {
        get '/A' => sub { '/c/1/A' };
    };
    prefix '/2' => sub {
        get '/A' => sub { '/c/2/A' };
        get '/B' => sub { '/c/2/B' };
    };
    prefix '/3' => sub {
        get '/A' => sub { '/c/3/A' };
        get '/B' => sub { '/c/3/B' };
        get '/C' => sub { '/c/3/C' };
    };
};

response_content_is $_ => $_, $_
    for qw#
        /a/1/A
        /b/1/A
        /b/2/A
        /b/2/B
        /c/1/A
        /c/2/A
        /c/2/B
        /c/3/A
        /c/3/B
        /c/3/C
    #;

