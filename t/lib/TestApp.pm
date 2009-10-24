package TestApp;

use Dancer;
use Data::Dumper;

get '/name/:name' => sub {
    "Your name: ".params->{name}
};

post '/name' => sub {
    "Your name: ".params->{name}
};

get '/env' => sub { Dumper(\%ENV) };

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

true;
