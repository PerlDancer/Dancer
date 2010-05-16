use Test::More import => ['!pass'];
use strict;
use warnings;

plan tests => 2;

use Dancer ':syntax';
use Dancer::Test;

{
    before sub { 
        unless (params->{'requested'}) {
            return halt("stoped");
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

response_content_is [GET => '/'], "stoped";
response_content_is [GET => '/', {requested => 1}], "route";
