use strict;
use warnings;

use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

plan tests => 5;

my $i = 0;

ok(
    hook 'before_error_render' => sub {
        my $error = shift;
        is $error->code, 404;
        $i++;
    }
);

ok(
    hook 'after_error_render' => sub {
        my $response = shift;
        is $response->status, 404;
        $i++;
    }
);

get '/' => sub {
    send_error("fake error", 404);
};

my $response = dancer_response( GET => '/' );
is $i, 2;
