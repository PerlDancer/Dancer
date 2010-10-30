package t::lib::TestAppUnicode;

use Dancer;

get '/string' => sub {
    "\x{1A9}";
};

get '/param/:param' => sub {
    params->{'param'};
};

get '/view' => sub {
    template 'unicode', { token => 'Ʃ' }
};

1;
