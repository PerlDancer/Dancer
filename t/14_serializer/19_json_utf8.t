use strict;
use warnings;

use Test::More tests => 1;

use utf8;
use Dancer::Serializer::JSON;

my $data = { foo => 'café' };

is Dancer::Serializer::JSON::from_json(
    Dancer::Serializer::JSON::to_json( $data )
)->{foo} => $data->{foo}, "encode/decode round-trip";



