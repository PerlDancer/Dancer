use strict;
use warnings;
use Test::More tests => 2, import => ['!pass'];
use Dancer;

use lib 't/lib';
use EasyMocker;

my $mock_loads = { };

mock 'Dancer::ModuleLoader' 
    => method 'load' 
    => should sub { $mock_loads->{$_[1]}};

# when CGI::Session is not here, session cannot be set
$mock_loads->{'CGI::Session'} = 0;
eval { set(session => 1) };
like($@, qr/The session engine needs CGI::Session to be installed/, 
    "the session engine depends on CGI::Session");

# when present, it can be
$mock_loads->{'CGI::Session'} = 1;
eval { set(session => 1) };
is($@, '', "the session engine can be set with CGI::Session");

