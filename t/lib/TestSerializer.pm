package t::lib::TestSerializer;

use Dancer ':syntax';

set serializer => 'JSON';

get '/' => sub {
    { foo => 1 }
};

post '/' => sub {
    request->params; 
};

1;
