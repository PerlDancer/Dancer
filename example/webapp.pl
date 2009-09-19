#!/usr/bin/perl

use Dancer;
use Template;

before sub {
    var note => "I ARE IN TEH BEFOR FILTERZ";
    debug "in the before filter";
};

get '/foo/*' => sub {
    my ($match) = splat; # ('bar/baz')
    debug "je suis dans /foo";
   
    use Data::Dumper;

    "note: '".vars->{note}."'\n<BR>".
    "match: $match\n<BR>".
    "request: ".Dumper(request);
};

# for testing Perl errors
get '/error' => sub {
    template();   
};

get '/' => sub {
    debug "welcome to the home";
    template 'index', {note => vars->{note}};
};

get '/hello/:name' => sub {
    template 'hello';
};

get '/page/:slug' => sub {
    template 'index' => {
        message => 'This is the page '.params->{slug},    
    };
};

post '/new' => sub {
    "creating new entry: ".params->{name};
};

get '/say/:word' => sub {
    content_type "text/plain";
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

dance;
