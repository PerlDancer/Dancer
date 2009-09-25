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

true;
