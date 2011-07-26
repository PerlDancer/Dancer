use strict;
use warnings;


use Test::More import => ['!pass'];
use Dancer::Test;

# All these paths should return 404; if we get a file served, we have a
# directory traversal vulnerability!
my @try_paths = qw(
    /css/../../secretfile
    ../secretfile
    /etc/passwd
    ../../../../../../../../../../../../etc/passwd
);

plan tests => scalar @try_paths * 3;

use Dancer ':syntax';

set public => path( dirname(__FILE__), 'static' );
my $public = setting('public');

for my $path (@try_paths) {
    ok my $resp = Dancer::Test::_get_file_response( [ GET => $path ] ),
        "Got a response for request to $path";;
    is $resp->{status},  404, "Response status was 404 for request to $path";
    ok !$resp->{content}, "No content returned for request to $path";
}

