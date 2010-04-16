use strict;
use warnings;

use Test::More tests => 3, import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

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

    response_content_is [GET => "/"], $test->{expected}, $test->{txt};
}
