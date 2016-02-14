use Test::More import => ['!pass'];
use Dancer ':syntax';

use Dancer::Session::Abstract;

plan tests => 10;

eval {
    Dancer::Session::Abstract->retrieve
};
like $@, qr{not implemented}, 
    "retrieve is a virtual method";

eval {
    Dancer::Session::Abstract->create
};
like $@, qr{not implemented}, 
    "create is a virtual method";

eval {
    Dancer::Session::Abstract->flush
};
like $@, qr{not implemented}, 
    "flush is a virtual method";

eval {
    Dancer::Session::Abstract->destroy
};
like $@, qr{not implemented}, 
    "destroy is a virtual method";


my $s = Dancer::Session::Abstract->new;
isa_ok $s, 'Dancer::Session::Abstract';
ok(defined($s->id), "id is defined");

is $s->session_name, 'dancer.session', "default name is dancer.session";

setting session_name => "foo_session";
$s = Dancer::Session::Abstract->new;
is $s->session_name, 'foo_session', 'setting session_name is used';

Dancer::Cookies->cookies->{$s->session_name} = Dancer::Cookie->new(
    name => $s->session_name,
    value => '../../../../../../../etc/passwd',
);
is ($s->read_session_id, undef, "Invalid session ID ignored");

Dancer::Cookies->cookies->{$s->session_name} = Dancer::Cookie->new(
    name => $s->session_name,
    value => '123456789',
);
is( $s->read_session_id, '123456789', "Valid-looking session ID accepted" );

