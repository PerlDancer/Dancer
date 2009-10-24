use Test::More tests => 5;

use strict;
use warnings;

use_ok 'Dancer::Logger::File';

my $l = Dancer::Logger::File->new;

ok defined($l), 'Dancer::Logger::File object';
isa_ok $l, 'Dancer::Logger::File';
can_ok $l, qw(init _log debug warning error);

my $format = Dancer::Logger::File::_format('debug', 'test');
like $format, qr/\[$$\] \(debug\) test in/, 
    "format looks good";
