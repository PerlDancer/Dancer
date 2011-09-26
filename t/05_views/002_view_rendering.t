use Dancer ':tests';
use Test::More;
use Dancer::Test;

my $views = path(dirname(__FILE__), 'views');
set views => $views;

my $time = time();

set show_errors => 1;

my @tests = (
    { path => '/',
      expected => "in view index.tt: number=\"\"\n" },
    { path => '/number/42',
      expected => "in view index.tt: number=\"42\"\n" },
    { path => '/clock',
      expected => "$time\n"},
    { path => '/request',
      expected => "/request\n" },
    { path => '/vars',
      expected => "bar\n" },
);

plan tests => 2 + scalar(@tests);

# 1. Check setting variables
{
    is setting("views") => $views, "Views setting was correctly set";

    ok !defined(setting("layout")), 'layout is not defined';
}

# 2. Check views
# test simple rendering

get '/' => sub {
    template 'index';
};

get '/with_fh' => sub {
    my $fh;

    die "TODO";
};

# test params.foo in view
get '/number/:number' => sub {
    template 'index'
};

# test token interpolation
get '/clock' => sub {
    template clock => { time => $time };
};

# test request.foo in view
get '/request' => sub {
    template 'request';
};

# test vars in view
get '/vars' => sub {
    var foo => 'bar';
    template 'vars';
};

foreach my $test (@tests) {
    my $path = $test->{path};
    my $expected = $test->{expected};

    response_content_is [GET => $path] => $expected;

}
