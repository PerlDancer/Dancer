use Dancer ':tests';
use Test::More;
use Dancer::Test;

get '/' => sub {
    "hello"
};

get '/not_found' => sub {
    status 'not_found';
    "not here";
};

get '/500' => sub { status 500 };

my @tests = (
    { path => '/', expected => 200},
    { path => '/not_found', expected => 404},
    { path => '/500' => expected => 500 },
);

plan tests => scalar(@tests);

foreach my $test (@tests) {
    response_status_is [ GET => $test->{path} ] => $test->{expected};
}

