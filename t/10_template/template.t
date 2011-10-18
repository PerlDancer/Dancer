use Test::More import => ['!pass'];

plan tests => 2;

use strict;
use warnings;

{
    use Dancer;

    setting views => path('t', '10_template', 'views');
    get '/' => sub {
        template 'index', {foo => 42};
    };

    get '/nonexisting' => sub {
        template 'none', { error => 'yes' };
    };

}

use Dancer::Test;

response_content_is [GET => '/'], "foo => 42\n";
response_status_is  [GET => '/nonexisting'] => 500;
