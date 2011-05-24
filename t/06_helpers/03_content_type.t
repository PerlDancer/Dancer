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

plan tests => scalar(@tests);

foreach my $test (@tests) {
    response_headers_include [GET => $test->{path}], ['Content-Type' => $test->{expected}];
}
