package TestApp;

use Dancer;
use Data::Dumper;
use LinkBlocker;

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

any['put','post'] => '/jsondata' => sub {
    request->body;
};

post '/form' => sub {
    params->{foo};
};

get '/unicode' => sub {
    "cyrillic shcha \x{0429}",
};

get '/forward_to_unavailable_route' => sub {
    forward "/some_route_that_does_not_exist"
};

get '/issues/499/true' => sub {
    "OK" if system('true') == 0  
};

get '/issues/499/false' => sub {
    "OK" if system('false') != 0  
};

true;
