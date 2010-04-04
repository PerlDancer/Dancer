use strict;
use warnings;

use Test::More tests => 2, import => ['!pass'];
use Dancer ':syntax';
use t::lib::TestUtils;
use Dancer::SharedData;

my @requested_with = (
    {value => 'XMLHttpRequest', expected => 'ajax'},
    {   value    => 'FooBar',
        expected => 'not ajax'
    }
);

get '/ajax' => sub {
    if (request->is_ajax) {
        return "ajax";
    }
    else {
        return "not ajax";
    }
};

foreach my $test (@requested_with) {

    %ENV = ('HTTP_X_REQUESTED_WITH' => $test->{value},);

    my $request = fake_request(GET => "/ajax");
    Dancer::SharedData->request($request);
    my $response = Dancer::Renderer::get_action_response();
    is $response->{content}, $test->{expected}, $test->{expected};
}
