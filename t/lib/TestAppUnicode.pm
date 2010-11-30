package TestAppUnicode;
use Dancer;

get '/string' => sub {
    "\x{1A9}";
};

get '/param/:param' => sub {
    params('route')->{'param'};
};

get '/view' => sub {
    template 'unicode', { 
        pure_token => 'Ʃ', 
        param_token => params->{'string1'}, 
    };
};

get '/form' => sub {
    debug "params: ".to_json({params()});
    debug "utf8 : é-\x{1AC}";

    template('unicode', { 
        char => "é-\x{E9}",
        string1 => params->{'string1'},
        token => to_json { 'params' => { request->params} }
    })."\x{E9} - string1: ".params->{'string1'}
};


1;
