package TestSerializer;

use Dancer;
use Dancer::Serializer;

set serializer => 'JSON';

get '/' => sub {
    { foo => 1 }
};

post '/' => sub {
    request->params; 
};

1;
