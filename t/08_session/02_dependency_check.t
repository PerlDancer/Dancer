use strict;
use warnings;
use Test::More import => ['!pass'];

plan tests => 3;

use Dancer;
use lib 't/lib';
use EasyMocker;

my $mock_loads = { };

mock 'Dancer::ModuleLoader' 
    => method 'load' 
    => should sub { $mock_loads->{$_[1]}};

# when YAML is not here...
$mock_loads->{'YAML'} = 0;
eval { set(session => 'YAML') };
like($@, qr/YAML is needed and is not installed/, 
    "the YAML session engine depends on YAML");

# when present, I CAN HAZ
$mock_loads->{'YAML'} = 1;
eval { set(session => 'YAML') };
is($@, '', "the session engine can be set with CGI::Session");

# load an unknown session engine
eval { set(session => 'galactica') };
like $@, qr/unknown session engine 'galactica'/, 
    "Unknown session engine is refused";

