use Test::More tests => 6, import => ['!pass'];

use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use EasyMocker;

use_ok 'Dancer::Logger::Diag';

my $l = Dancer::Logger::Diag->new;

ok defined($l), 'Dancer::Logger::Diag object';
isa_ok $l, 'Dancer::Logger::Diag';
can_ok $l, qw(init _log debug warning error info);

my $format = $l->format_message('debug', 'test');
like $format, qr/\[\d+\] debug @.+> test in/,
    "format looks good";

my $diagged = 0;

mock 'Test::More::diag' => sub { $diagged++ };

$l->_log( debug => 'Perl Dancer test message' );

ok( $diagged, 'Reached diag() of Test::More' );
