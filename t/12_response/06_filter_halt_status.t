use strict;
use warnings;
use Test::More import => ['!pass'];;

plan skip_all => "JSON is needed to run this tests"
    unless Dancer::ModuleLoader->load('JSON');

# make sure we keep the status when halt is used

{
    package SomeApp;
    use Dancer;

    set serializer => 'JSON';
    set environment => 'production';

    hook before => sub {
        if (params->{'troll'}) {
            status 401;
            return halt({error => "Go away you troll!"})
        }
    };

    get '/' => sub {
        "root"
    };
}

use Dancer::Test;

my @tests = (
    ['/', {}, 200, 'root'],
    ['/', {troll => 1}, 401, 
        '{"error":"Go away you troll!"}'],
    );

plan tests => scalar(@tests) * 2;

for my $t (@tests) {
    my ($path, $params, $status, $content) = @{ $t };

    my $resp = dancer_response(GET => $path, { params => $params });
    is $resp->{status}, $status, "status is $status";
    is $resp->{content}, $content, "content is $content";
}


