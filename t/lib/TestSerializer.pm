package t::lib::TestSerializer;

use Dancer;

set serializer => 'JSON';

get '/' => sub {
    { foo => 1 }
};

post '/' => sub {
    request->params; 
};

get '/error' => sub {
    send_error({foo => 42}, 401);
};

get '/error_bis' => sub {
    send_error(42, 402);
};
1;
