use strict;
use warnings;

use Test::More tests => 7, import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

my $i = 0;


ok(get('/:id', sub { "whatever " . params->{id} }), 'installed basic route handler');

route_exists [GET => '/:id'];
response_status_is [GET => "/$i"], 200, 'before not installed yet, response status is 200 looks good for GET /0';
response_content_is [GET => "/$i"], "whatever $i";

ok(
   before(
      sub {
         ++$i;
         request->path_info("/$i");
      }
   ), 'installed before hook',
);
ok(! eval { dancer_response(GET => "/$i") }, 'before messes all up, route not OK any more');
like($@, qr{infinite loop}, 'infinite loop detected');
