use Test::More tests => 12, import => ['!pass'];
use strict;
use warnings;

use Dancer::Test;
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

{
    use Dancer;

    load_app 'TestApp';
    load_app 'Forum', prefix => '/forum';

    get '/' => sub { "home" };
}

my $apps = [ Dancer::App->applications ];
is scalar(@$apps), 3, "3 applications exist";

for (
    { name => "main",    routes => 1  },
    { name => "TestApp", routes => 22 },
    { name => "Forum",   routes => 5  },
)
{
    my $app = Dancer::App->get($_->{name});
    ok(
        defined($app)
        , "app $_->{name} is defined",
    );
    is(
        @{ $app->registry->routes('get') },
        $_->{routes},
        "Expected number of get routes defined for " . $_->{name},
    );
}

response_content_is [GET => "/forum/index"], "forum index"; 
response_content_is [GET => "/forum/admin/index"], "admin index"; 
response_content_is [GET => "/forum/users/list"], "users list"; 
response_content_is [GET => "/forum/users/mods/list"], "mods list"; 
response_content_is [GET => "/forum/"], "root"; 
