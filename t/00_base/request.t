use Test::More;

BEGIN {
    plan tests => 12;
    use_ok 'Dancer::Request';
}

my $r;

eval { $r = Dancer::Request->new };
like $@, qr/Cannot resolve path/, "not enough information to find the path";

eval { $r = Dancer::Request->new(path => '/foo', method => "GET") };
is $@, '', "can create from hash";

isa_ok $r, 'Dancer::Request';
can_ok $r, qw(path path_info method request_method);
is $r->method, 'GET', "method is GET";
is $r->path, '/foo', "path is /foo";

eval { $r2 = Dancer::Request->new(request => $r) };
is $@, '', "can create from Dancer::Request object";

isa_ok $r, 'Dancer::Request';
can_ok $r, qw(path path_info method request_method);
is $r->method, 'GET', "method is GET";
is $r->path, '/foo', "path is /foo";

