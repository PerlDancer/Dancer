use Dancer ':tests';
use Test::More;
use Dancer::Test;

plan tests => 10;

var foo => 0;

get '/' => sub { vars->{foo} += 1; vars->{foo} };

for(1..10) {
    response_content_is [GET => '/'], 1, "foo is 1";
}
