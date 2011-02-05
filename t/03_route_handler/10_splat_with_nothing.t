use Test::More import => ['!pass'];
plan tests => 1;

{
    use Dancer;

    get '/' => sub {
        splat;
    };
}

use Dancer::Test;

response_content_is [GET => '/'], '';
