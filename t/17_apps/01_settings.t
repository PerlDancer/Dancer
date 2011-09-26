use Test::More tests => 6;
use strict;
use warnings;

use Dancer::App;
use Dancer::Test;

my $app = Dancer::App->new;

is_deeply $app->settings, {}, 
    "settings is an empty hashref";

is $app->setting('foo'), undef,
    "setting 'foo' is undefined";

ok $app->setting('foo' => 42), 
    "set the 'foo' setting to 42";

is $app->setting('foo'), 42,
    "setting 'foo' is 42";

# a setting could be overwritten by a Dancer::App instance

{ 
    package Webapp;
    use Dancer;

    setting onlyroot => 42;
    setting foo => "root";

    get '/root_action' => sub {
        return {
                onlyroot => setting('onlyroot'),
                foo => setting('foo'),
                onlyapp => setting('onlyapp') 
               };
    };

    use File::Spec;
    use lib File::Spec->catdir( 't', 'lib' );
    load_app 'TestApp',
      settings => {
                   foo => 'testapp',
                   onlyapp => '43',
                  };
}


response_content_is_deeply [ GET => '/root_action' ], { 
        onlyroot => 42,
        foo => 'root',
        onlyapp => undef, 
    };
response_content_is_deeply [ GET => '/test_app_setting' ], { 
        onlyroot => 42,
        foo => 'testapp',
        onlyapp => 43, 
    };
