use Test::More;

plan tests => 1;

{
    use Dancer ':tests';

    get '/:foo' => sub {
        param 'foo';
    };
}

use Dancer::Test;

response_content_is [GET => '/42'], 42;
