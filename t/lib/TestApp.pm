package TestApp;
use Dancer;

get '/name/:name' => sub {
    "Your name: ".params->{name}
};

get '/' => sub {
    "Your name: xxx"
};

true;
