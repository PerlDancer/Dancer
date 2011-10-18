use strict;
use warnings;

use Test::More tests => 6, import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

my $i = 0;

set show_errors => 1;

ok(get('/:id', sub { "whatever " . params->{id} }), 'installed basic route handler');

route_exists [GET => '/:id'];
response_status_is [GET => "/$i"] => 200,
  'before not installed yet, response status is 200 looks good for GET /0';
response_content_is [GET => "/$i"], "whatever $i";

hook before => sub {
    ++$i;
    request->path_info("/$i");
};


response_status_is    [GET => "/$i"] => 500, "Right request status";
response_content_like [GET => "/$i"] => qr{infinite loop}, "infinite loop detected";

