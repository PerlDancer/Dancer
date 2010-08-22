use strict;
use warnings;

use Test::More import => ['!pass'];
use Dancer ':syntax';

plan tests => 6;

use Dancer::Session::Simple;

my $session = Dancer::Session::Simple->create;
isa_ok $session, 'Dancer::Session::Simple';

ok( defined( $session->id ), 'ID is defined' );

is( Dancer::Session::Simple->retrieve('XXX'),
    undef, "unknown session is not found" );

my $s = Dancer::Session::Simple->retrieve( $session->id );
is_deeply $s, $session, "session is retrieved";

$session->{foo} = 42;
$session->flush;
$s = Dancer::Session::Simple->retrieve( $s->id );
is_deeply $s, $session, "session is changed on flush";

my $id = $s->id;
$s->destroy;
$session = Dancer::Session::Simple->retrieve($id);
is $session, undef, 'session is destroyed';
