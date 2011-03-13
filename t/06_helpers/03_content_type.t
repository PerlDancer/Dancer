use Dancer ':tests';
use Test::More;
use Dancer::Test;

get '/' => sub {
    "hello"
};

get '/text' => sub {
    content_type 'text/plain';
    "text";
};

get '/svg' => sub {
    content_type 'svg';
    "<svg/>";
};

get '/png' => sub {
    content_type 'png';
    "blergh";
};

my @tests = (
    { path => '/',     expected => setting('content_type')},
    { path => '/text', expected => 'text/plain'},
    { path => '/',     expected => setting('content_type')},
    { path => '/text', expected => 'text/plain'},
    { path => '/svg',  expected => 'image/svg+xml'},
    { path => '/png',  expected => 'image/png'},
);

plan tests => scalar(@tests) * 2;

foreach my $test (@tests) {
    my $response = dancer_response(GET => $test->{path});
    ok(defined($response), "route handler found for ".$test->{path});
    is $response->header('Content-Type'), $test->{expected};
}
