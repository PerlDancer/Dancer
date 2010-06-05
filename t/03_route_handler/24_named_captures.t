use strict;
use warnings;
use Test::More 'no_plan', import => ['!pass'];

use t::lib::TestUtils;

use Dancer ':syntax';
use Dancer::Route; 
ok ( get( qr{
	/ (?<class> user | content | post )
	/ (?<action> delete | find )
	/ (?<id> \d+ )
	}x, sub { captures }
    ), 'first route set'
);

for my $test
(  
    { path     => '/user/delete/234'
    , expected => {qw/ class user action delete id 234 /}
    }
) {
     my $handle;
     my $path = $test->{path};
     my $expected = $test->{expected};
     my $request = fake_request(GET => $path);
 
     Dancer::SharedData->request($request);
     my $response = Dancer::Renderer::get_action_response();
        
     ok( defined($response), "route handler found for path `$path'");
     is_deeply(
         $response->{content}, $expected, 
         "match data for path `$path' looks good");
}
