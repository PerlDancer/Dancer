use Test::More import => ['!pass'];
use strict;
use warnings;

plan tests => 2;

use Dancer ':syntax';
use Dancer::Test;

{
    before sub { 
        unless (params->{'requested'}) {
            return halt("stopped");
        }
    };

    before sub {
        unless (params->{'requested'}) {
            halt("another halt");
        }
    };

    get '/' => sub {
        "route"
    };
}

response_content_is [GET => '/'], "stopped";
response_content_is [GET => '/', { params => {requested => 1} }], "route";
#my $res = dancer_response GET => '/', { params => {requested => 1} };
#is $res->{content}, "route", "good";
