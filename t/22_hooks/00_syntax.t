use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';

plan tests => 4;

ok( hook(before => sub { 'block before' } ), 'add a before filter' );
ok( hook(after => sub  { 'block after' } ),  'add an after filter' );

ok( hook(before_template=> sub { 'block before_template' } ),
    'add a before_template filter' );

eval {
    hook( 'before', 'This is not a CodeRef' ),
};
like($@, qr/the code argument passed to hook construction was not a CodeRef. Value was : 'This is not a CodeRef' at/, 'a non coderef is properly caught');
