use Test::More;

plan tests => 2;

{
    use Dancer ':tests';
diag setting('allow_encoded_slashes');

    get '/:foo/baz' => sub {
        param 'foo';
    };

    get '/:foo/:bar/baz' => sub {
        param 'foo';
    };
}

use Dancer::Test;
use Dancer::Config 'setting';

# CGI.pm used by HTTP::Server::Simple is the real culprit, so we cannot test the 'Off' mode here
#
# # set allow_encoded_slashes => 'Off';
# setting('allow_encoded_slashes' => 'Off');
# response_content_is [GET => '/42%2F42/baz'], '42';

# set allow_encoded_slashes => 'On';
setting('allow_encoded_slashes' => 'On');
response_content_is [GET => '/42%2F42/baz'], '42/42';

# set allow_encoded_slashes => 'NoDecode';
setting('allow_encoded_slashes' => 'NoDecode');
response_content_is [GET => '/42%2F42/baz'], '42%2F42';
