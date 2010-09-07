package MyApp;

use Dancer ':syntax';

load_app 'MyAppFoo', prefix => '/foo';
get '/' => sub {'mainapp'};

1;
