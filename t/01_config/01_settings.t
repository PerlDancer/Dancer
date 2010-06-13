use strict;
use warnings;

use Test::More tests => 5, import => ['!pass'];

use Dancer ':syntax';

# testing default values
is(setting('port'), '3000', "default value for 'port' is OK"); 
is(setting('content_type'), 'text/html', "default value for 'content_type' is OK"); 

# testing new settings
ok(setting(foo => '42'), 'setting a new value');
is(setting('foo'), 42, 'new value has been set');

# test the alias 'set'
is(set(bar => 43), 43, "setting bar with set");
