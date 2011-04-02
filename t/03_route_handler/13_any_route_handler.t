use strict;
use warnings;
use Test::More tests => 17, import => ['!pass'];
use Dancer::Test;

use Dancer ':syntax';

eval {
    any ['get', 'delete'] => '/any_1' => sub { 
        "any_1"
    };
};
is $@, '', "route defined for methods get and delete; for path /any_1";

eval {
    any '/any_2' => sub { 
        "any_2"
    };
};
is $@, '', "route defined for any method; for path /any_1";

eval {
    any 'get' => '/any_1' => sub { 
        "any_1"
    };
};
like $@, qr/Syntax error, methods should be provided as an ARRAY ref/, 
    "syntax error caught";

my @routes = (
    {
        methods => ['get', 'delete'],
        path => '/any_1',
        expected => 'any_1',
    },
    {
        methods => ['get', 'delete', 'post', 'put'],
        path => '/any_2',
        expected => 'any_2',
    }
);

# making sure response are OK
foreach my $route (@routes) {
    foreach my $method (@{ $route->{methods} }) {
        response_exists [$method => $route->{path}],
          "route handler found for method $method, path ".$route->{path};

        response_content_is [$method => $route->{path}], $route->{expected},
          "response content is ok";
    }
}

# making sure 404 are thrown for unspecified routes
my @failed = (
    {
        methods => ['post', 'put'],
        path => '/any_1',
    },
);

foreach my $route (@failed) {
    foreach my $method (@{ $route->{methods} }) {
        response_status_is [$method => $route->{path}] => 404,
          "route handler not found for method $method, path ".$route->{path};
    }
}
