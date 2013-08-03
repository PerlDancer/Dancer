use strict;
use warnings;

use Test::More tests => 1;

use Dancer ':tests';
use Dancer::Test;

# failsafe
my $level = 1;

set session => 'Simple';

get "/index" => sub {
    session player => "Groo";
    $level++;
    forward "/main";
};

get "/main" => sub {
    die "urrrgh" if $level > 10;
    forward("/index") unless session("player");
    "Hello world, " . session("player") . "!";
};

response_content_is '/index' => 'Hello world, Groo!', 
    'session is maintained by the forward';
