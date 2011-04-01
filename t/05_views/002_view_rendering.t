use Dancer ':tests';
use Test::More;
use Dancer::Test;

set views => path(dirname(__FILE__), 'views');

my $time = time();

set show_errors => 1;

my @tests = (
    { path => '/',
      expected => "in view index.tt: number=\"\"\n" },
    { path => '/number/42',
      expected => "in view index.tt: number=\"42\"\n" },
    { path => '/clock', expected => "$time\n"},
    { path => '/request', expected => "/request\n" },
);

plan tests => scalar(@tests);

# test simple rendering
get '/' => sub {
    template 'index';
};

get '/with_fh' => sub {
    my $fh;
    
    die "TODO";
};

use Data::Dumper;

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

foreach my $test (@tests) {
    my $path = $test->{path};
    my $expected = $test->{expected};
    
    my $resp = dancer_response(GET => $path);
    is($resp->content, $expected, "content rendered looks good for $path");
}
