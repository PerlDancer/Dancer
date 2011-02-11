use strict;
use warnings;

use Test::More import => ['!pass'];
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use TestUtils;

use Dancer ':syntax';

get '/onecookie', sub {
        set_cookie 'A'=> "thevalueofA";
        return '';
};

get '/twocookies', sub {
        set_cookie 'A'=> "thevalueofA";
        set_cookie 'B'=> "thevalueofB";
        return '';
};

plan tests => 2;

# /onecookie
my $req = fake_request(GET => '/onecookie');
Dancer::SharedData->request($req);
my $headers = Dancer::Renderer::render_action();
ok($headers->header('Set-Cookie') eq 'A=thevalueofA; path=/; HttpOnly');

# /twocookies
$req = fake_request(GET => '/twocookies');
Dancer::SharedData->request($req);
$headers = Dancer::Renderer::render_action();
ok($headers->header('Set-Cookie') eq 'A=thevalueofA; path=/; HttpOnly, B=thevalueofB; path=/; HttpOnly');
