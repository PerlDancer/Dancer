use strict;
use warnings;

use lib 't/lib';

use Test::More;

BEGIN {
    plan skip_all => 'module Template::Provider::FromDATA required' 
        unless eval "use Template::Provider::FromDATA; 1";
}

use FromDataApp;
use Dancer::Test;

plan tests => 1;

response_content_like '/' => qr/Hello embedded world!/, 
    'embedded template work';





