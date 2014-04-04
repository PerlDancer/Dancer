use strict;
use warnings;

BEGIN {
    use Test::More;

    plan skip_all => 'Devel::Hide required' unless eval 'use Devel::Hide; 1';
}

use Devel::Hide 'Clone';

plan tests => 3;

{ 
    package MyApp;

    use Dancer;

    my $data = { deep => { secret => 'akadabra' } };

    get '/dump' => sub { Dancer::Error::dumper( $data ) };
    get '/straight' => sub { $data->{deep}{secret} };
}

use Dancer::Test;


response_content_is '/straight' => 'akadabra', 'secret visible';

response_content_like '/dump' => qr/secret.*Hidden/, 'masked by dumper()';

response_content_is '/straight' => 'akadabra', '...but not modified';


