use Dancer ':tests', ':syntax';
use Dancer::Test;
use Test::More;

my @methods = qw(get head put post delete options);

plan tests => @methods * 3;

get     '/' => sub { 'get'     };
post    '/' => sub { 'post'    };
put     '/' => sub { 'put'     };
del     '/' => sub { 'delete'  };
options '/' => sub { 'options' };

foreach my $m (@methods) {
    route_exists       [ $m => '/' ], "route handler found for method $m";
    response_status_is [ $m => '/' ] => 200, "response status is 200 for $m";

    my $content = $m;
    $content = '' if $m eq 'head';
    response_content_like [ $m => '/' ] => qr/$content/,
      "response content is OK for $m";
}
