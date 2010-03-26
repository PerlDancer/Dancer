use strict;
use warnings;
use Test::More 'import' => ['!pass'], tests => 10;

{
    package Dancer::Plugin::LinkBlocker;
    use Dancer ':syntax';
    use Dancer::Plugin;

    register block_links_from => sub {
        my ($host) = @_;
        before sub { 
            if (request->referer =~ /http:\/\/$host/) {
                status 403;
            }
        };
    };

    package Webapp;
    use Dancer;
    use Dancer::Plugin::Foo;

    block_links_from 'www.foo.com';

    get '/' => sub { "gotcha" }
}

use lib 't';
use TestUtils;
use Webapp;

$ENV{HTTP_REFERER} = 'http://www.google.com';
my $response = get_response_for_request(GET => '/');
is $response->{status}, 200, "referer is not blocked";

