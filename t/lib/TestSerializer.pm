package TestSerializer;

use Dancer;
use Dancer::Serializer;

my $engine = Dancer::Serializer->init();

get '/' => sub {
    _serialize();
};

post '/' => sub {
    _deserialize();
};

sub _serialize {
    $engine->serialize( { foo => 1 } );
}

sub _deserialize {
    $engine->deserialize();
    my $p = Dancer::SharedData->request->params;
    return $engine->serialize($p);
}

1;
