use Test::More import => ['!pass'];

use strict;
use warnings;
use Dancer;
use Dancer::ModuleLoader;
use Dancer::Config 'setting';

BEGIN { 
    plan skip_all => "need Crypt::CBC" 
        unless Dancer::ModuleLoader->load('Crypt::CBC');
    plan skip_all => "need String::CRC32" 
        unless Dancer::ModuleLoader->load('String::CRC32');
    plan skip_all => "need Crypt::Rijndael" 
        unless Dancer::ModuleLoader->load('Crypt::Rijndael');
    plan tests => 7;
    use_ok 'Dancer::Session::Cookie' 
}

use lib 't/lib';
use EasyMocker;

my $loader_mock = {'Crypt::CBC' => 0, 'String::CRC32' => 0, 'Crypt::Rijndael' => 0};
mock 'Dancer::ModuleLoader' 
    => method 'load' => should sub { $loader_mock->{$_[1]} };

my $session;
setting session_cookie_key => 'test/secret*@?)';

eval { $session = Dancer::Session::Cookie->create };
like $@, qr/Crypt::CBC/, "Need Crypt CBC";

$loader_mock->{'Crypt::CBC'} = 1;
eval { $session = Dancer::Session::Cookie->create };
like $@, qr/String::CRC32/, "Need String::CRC32";

$loader_mock->{'String::CRC32'} = 1;
eval { $session = Dancer::Session::Cookie->create };
like $@, qr/Crypt::Rijndael/, "Need Crypt::Rijndael";

$loader_mock->{'Crypt::Rijndael'} = 1;

eval { $session = Dancer::Session::Cookie->create };
is $@, '', "Cookie session created";

isa_ok $session, 'Dancer::Session::Cookie';
can_ok $session, qw(init create retrieve destroy flush);

# see ./03_http_requests.t for a full functional test
