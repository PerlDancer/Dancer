use Test::More tests => 5, import => ['!pass'];
use Dancer::Test;
use strict;
use warnings;

use Dancer;

eval { load_app 'UnexistentApp' };
like $@, qr/unable to load application UnexistentApp : Can't locate/, 
    'load_app fails if the app is not found';

eval { load_app 'AppWithError' };
like $@, qr/unable to load application AppWithError : Bareword/, 
    'load_app fails if the app has syntax errors';

eval { load_app 'WorkingApp' };
is $@, '', "WorkingApp loaded";

route_exists [ GET => '/app'];
response_content_is [ GET => '/app'], "app";
