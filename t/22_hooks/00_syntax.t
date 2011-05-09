use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';

plan tests => 4;

ok( before( sub { 'block before' } ), 'add a before filter' );
ok( after( sub  { 'block after' } ),  'add an after filter' );

ok( before_template( sub { 'block before_template' } ),
    'add a before_template filter' );

ok(
    hook( 'before', sub { 'block before' } ),
    'add a before filter using the hook keyword'
);
