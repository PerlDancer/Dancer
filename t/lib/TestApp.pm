package t::lib::TestApp;

use Dancer;
use Data::Dumper;
use t::lib::LinkBlocker;

block_links_from "www.foo.com";

get '/' => sub { "Hello, this is the home" };

get '/name/:name' => sub {
    "Your name: ".params->{name}
};

post '/params/:var' => sub {
    Dumper({
        params => scalar(params),
        route  => { params('route') },
        query  => { params('query') },
        body   => { params('body') }
    });
};

post '/name' => sub {
    "Your name: ".params->{name}
};

get '/env' => sub { Dumper(Dancer::SharedData->request) };

get '/cookies' => sub { Dumper(cookies()) };

get '/set_cookie/*/*' => sub {
    my ($name, $value) = splat;
    set_cookie $name => $value;
};

get '/set_session/*' => sub {
    my ($name) = splat;
    session name => $name;
};

get '/read_session' => sub {
    "name='".session('name')."'"
};

put '/jsondata' => sub {
    request->body;
};

true;
