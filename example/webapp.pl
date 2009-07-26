#!/usr/bin/perl

use Dancer;
use Template;

get '/' => sub {
    send_file '/index.html'

};

get '/test' => sub {
    template index => {token => 42};
};

get '/hello/:name' => sub {
    template 'hello';
};

post '/new' => sub {
    "creating new entry: ".params->{name};
};

get '/say/:word' => sub {
    if (params->{word} =~ /^\d+$/) {
        pass and return false;
    }
    "I say a word: '".params->{word}."'";
};

get '/download/*.*' => sub { 
    my ($file, $ext) = splat;
    "Downloading $file.$ext";
};

get '/say/:number' => sub {
    pass if (params->{number} == 42); # this is buggy :)
    "I say a number: '".params->{number}."'";
};

# this is the trash route
get r('/(.*)') => sub {
    my ($trash) = splat;
    status 'not_found';
    "got to trash: $trash";
};

Dancer->dance;
