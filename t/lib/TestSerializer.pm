package t::lib::TestSerializer;

use Dancer;

set serializer => 'JSON';

get '/' => sub {
    { foo => 1 }
};

post '/' => sub {
    request->params; 
};

1;
