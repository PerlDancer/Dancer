package Forum;

use Dancer ':syntax';
use TestPlugin;

get '/' => sub { "root" };
get '/index' => sub { 'forum index' };

prefix '/admin';
get '/index' => sub { 'admin index' };

prefix '/users' => sub {
    get '/list' => sub { 'users list' };
    
    prefix '/mods';
    get '/list' => sub { 'mods list' };
};

1;
