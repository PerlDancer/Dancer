use Test::More tests => 6, import => ['!pass'];

use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use EasyMocker;

use_ok 'Dancer::Logger::Note';

my $l = Dancer::Logger::Note->new;

ok defined($l), 'Dancer::Logger::Note object';
isa_ok $l, 'Dancer::Logger::Note';
can_ok $l, qw(init _log debug warning error info);

my $format = $l->format_message('debug', 'test');
like $format, qr/\[\d+\] debug @.+> test in/,
    "format looks good";

my $noted = 0;

mock 'Test::More::note' => sub { $noted++ };

$l->_log( debug => 'Perl Dancer test message' );

ok( $noted, 'Reached note() of Test::More' );
