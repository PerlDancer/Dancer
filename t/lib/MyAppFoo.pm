package MyAppFoo;

use Dancer ':syntax';

before sub {
    halt ('before block in foo');
};

get '/' => sub {
    'get in package MyAppFoo';
};

1;
