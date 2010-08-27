use Test::More 'tests' => 6;
use Dancer::Test;

use strict;
use warnings;

my $not_redirected_content = 'gotcha';

{
    package Webapp;
    use Dancer;

    get '/' => sub { 
        "home";
    };

    get '/cond_bounce' => sub {
        if(params->{'bounce'}) {
            redirect '/';
            return;
        }

        $not_redirected_content;
    };
}

my $req = [GET => '/cond_bounce', { params => { bounce => 1 } }];
response_exists $req, "response for /cond_bounce, with bounce param";
response_status_is $req, 302, 'status is 302';
response_content_is $req, '', 'content is empty when bounced';

$req = [GET => '/cond_bounce'];
response_exists $req, "response for /cond_bounce without bounce param";
response_status_is $req, 200, 'status is 200';
response_content_is $req, $not_redirected_content, 'content is not empty';
