use Test::More import => ['!pass'];

use strict;
use warnings;

{
    use Dancer;

    setting views => path('t', '10_template', 'views');
    get '/' => sub {
        template 'index.tt';
    };
}

use Dancer::Test;

response_content_is [GET => '/'], '';
