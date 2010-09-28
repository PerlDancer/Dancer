package t::lib::TestApp;

use Dancer;
use Data::Dumper;
use t::lib::LinkBlocker;

block_links_from "www.foo.com";

get '/' => sub { "Hello, this is the home" };
get '/hash' => sub { { a => 1, b => 2, c => 3} };
get '/with_headers' => sub {
    header 'X-Foo-Dancer' => 42;
    1;
};
get '/headers_again' => sub { request->header('X-Foo-Dancer') };


get '/test_app_setting' => sub {
    return { 
        onlyroot => setting('onlyroot'),
        foo => setting('foo'),
        onlyapp => setting('onlyapp') 
    };
};

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
    my $name = session('name') || '';
    "name='$name'"
};

put '/jsondata' => sub {
    request->body;
};

post '/form' => sub {
    params->{foo};
};

get '/unicode' => sub {
    "cyrillic shcha \x{0429}",
};

true;
