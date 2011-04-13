use Test::More import => ['!pass'];

plan tests => 2;

use strict;
use warnings;

{
    use Dancer;

    set views => path('t', '10_template', 'views');
    set template => 'simple';
    set 'engines/simple/extension' => 'ts';

    get '/' => sub {
        template 'index', { bar => 42};
    };
}

use Dancer::Test;

is (setting('engines/simple/extension'), 'ts', "Extension is set");
response_content_is [GET => '/'], "bar => 42\n";


