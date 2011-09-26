package MyAppFoo;

use Dancer ':syntax';

before {apps => [qw/MyAppFoo/]}, sub {
    halt('before block in foo');
};

get '/' => sub {
    'get in package MyAppFoo';
};

1;
