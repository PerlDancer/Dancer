use Test::More import => ['!pass'];

plan tests => 1;

use strict;
use warnings;

{
    use Dancer;
    use Dancer::Template;

    my $config = {
                  engines => {
                              simple => {
                                         extension => 'ts',
                                        },
                             },
                 };

    setting views => path('t', '10_template', 'views');

    Dancer::Template->init("simple", $config);

    get '/' => sub {
        template 'index', { bar => 42};
    };
}

use Dancer::Test;

response_content_is [GET => '/'], "bar => 42\n";
