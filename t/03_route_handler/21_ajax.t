use strict;
use warnings;

use Test::More tests => 3, import => ['!pass'];
use Dancer ':syntax';
use t::lib::TestUtils;
use Dancer::SharedData;

my @requested_with = (
    {value => 'XMLHttpRequest', expected => 'ajax', txt => 'valid ajax route'},
    {   value    => 'FooBar',
        expected => undef,
        txt      => 'unvalid ajax route',
    }
);

ok( ajax(
        '/',
        sub {
            return "ajax";
        }
    ),
    'defined ajax route'
);

foreach my $test (@requested_with) {

    %ENV = ('HTTP_X_REQUESTED_WITH' => $test->{value},);

    my $request = fake_request(GET => "/");
    Dancer::SharedData->request($request);
    my $response = Dancer::Renderer::get_action_response();
    is $response->{content}, $test->{expected}, $test->{txt};
}
