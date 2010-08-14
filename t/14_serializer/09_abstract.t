use Test::More;

use Dancer::Serializer::Abstract;

eval { 
    Dancer::Serializer::Abstract->serialize()
};
like $@, qr{must be implemented},
    "serialize is a virtual method";

eval { 
    Dancer::Serializer::Abstract->deserialize()
};
like $@, qr{must be implemented},
    "deserialize is a virtual method";

is(Dancer::Serializer::Abstract->loaded, 0,
    "loaded is 0");

is(Dancer::Serializer::Abstract->content_type, "text/plain",
    "content_type is text/plain");

ok(Dancer::Serializer::Abstract->support_content_type('text/plain'),
    "text/plain is supported");

ok(Dancer::Serializer::Abstract->support_content_type('text/plain; charset=utf8'),
    "text/plain; charset=utf8 is supported");

ok(! Dancer::Serializer::Abstract->support_content_type('application/json'),
    "application/json is not supported");

done_testing;
