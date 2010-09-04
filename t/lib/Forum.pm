package t::lib::Forum;

use Dancer ':syntax';
use t::lib::TestPlugin;

get '/' => sub { "root" };
get '/index' => sub { 'forum index' };

1;
