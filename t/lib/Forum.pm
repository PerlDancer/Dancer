package t::lib::Forum;

use Dancer ':syntax';

get '/' => sub { "root" };
get '/index' => sub { 'forum index' };

1;
