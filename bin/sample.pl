#!/usr/bin/perl

use Dancer;

get '/' => sub {
    "Hello There!"
};

get '/hello/:name' => sub {
    my %params = @_;

    "Hey ".$params{name}.", how are you?";
};

Dancer->dance;
