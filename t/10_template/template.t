use Test::More import => ['!pass'];

plan tests => 1;

use strict;
use warnings;

{
    use Dancer;

    setting views => path('t', '10_template', 'views');
    get '/' => sub {
        template 'index.tt', {foo => 42};
    };
}

use Dancer::Test;

response_content_is [GET => '/'], "foo => 42\n";
