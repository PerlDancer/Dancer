use Test::More tests => 6, import => ['!pass'];

use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use EasyMocker;

use_ok 'Dancer::Logger::Null';

my $l = Dancer::Logger::Null->new;

ok defined($l), 'Dancer::Logger::Null object';
isa_ok $l, 'Dancer::Logger::Null';
can_ok $l, qw(_log debug warning error info);

my $format = $l->format_message('debug', 'test');
like $format, qr/\[\d+\] debug @.+> test in/,
    "format looks good";

ok(
    $l->_log( debug => 'Perl Dancer test message' ),
    'Logged msg to Null',
);

