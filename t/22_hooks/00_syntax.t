use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';

plan tests => 5;

ok( before( sub { 'block before' } ), 'add a before filter' );
ok( after( sub  { 'block after' } ),  'add an after filter' );

ok( before_template( sub { 'block before_template' } ),
    'add a before_template filter' );

ok(
    hook( 'before', sub { 'block before' } ),
    'add a before filter using the hook keyword'
);

eval {
    hook( 'before', 'This is not a CodeRef' ),
};
like($@, qr/the code argument passed to hook construction was not a CodeRef. Value was : 'This is not a CodeRef' at/, 'a non coderef is properly caught');
