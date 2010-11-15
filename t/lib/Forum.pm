package Forum;

use Dancer ':syntax';
use TestPlugin;

get '/' => sub { "root" };
get '/index' => sub { 'forum index' };

1;
