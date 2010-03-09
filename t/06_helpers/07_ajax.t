use strict;
use warnings;

use Test::More tests => 1, import => ['!pass'];
use Dancer;
use lib 't';
use TestUtils;

%ENV = (
    'X-REQUESTED-WITH' => 'XMLHttpRequest',
);

get '/ajax' => sub {
    if (is_ajax) {
    warn "on est la ??\n";
        return "ajax";
    }
};

my $request = fake_request(GET => "/ajax");
use YAML::Syck;
Dancer::SharedData->request($request);
my $response = Dancer::Renderer::get_action_response();
print Dump $response;
ok 1;

done_testing;
