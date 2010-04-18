package AppWithError;
use Dancer ':syntax';

bogus_call_to_unkown_symbol;

get '/webapp' => sub { 'webapp' };

1;
