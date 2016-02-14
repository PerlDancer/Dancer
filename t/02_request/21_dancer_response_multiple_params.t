use Test::More tests => 2;
use strict;
use warnings;

use Dancer::Test;


{
    package MyApp;
    use Dancer ':tests';
    set logger => 'console';

    use Data::Dump;
    post '/things' => sub { Data::Dump::dump(params()) };
}

my $response = dancer_response POST => '/things',
    {body => { things => [ 'a', 'b' ] } };

is $response->status, 200;
is $response->content, '("things", ["a", "b"])';
