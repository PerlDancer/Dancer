use strict;
use warnings;
use Test::More import => ['!pass'];

plan tests => 7;

use Dancer ':syntax';
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );
use EasyMocker;
use Dancer::Session::YAML;

{
    # checking that EasyMocker works
    mock 'My::SuperModule'
        => method 'method'
        => should sub { ok( 1, 'EasyMocker mocked a method' ) };

    mock 'My::SuperModule'
        => method 'new_method'
        => should sub { 'blech' };

    eval { My::SuperModule->method };
    if ( !$@ ) {
        is( My::SuperModule->new_method, 'blech', 'Mocked method is good' );
    } else {
        ok( 0, 'Method mocking failed' );
    }
}

my $mock_loads = { };

mock 'Dancer::ModuleLoader' 
    => method 'load' 
    => should sub { $mock_loads->{ $_[1] } };

mock 'Dancer::Session::YAML'
    => method 'new'
    => should sub {1};

# when YAML is not here...
$mock_loads->{'Dancer::Session::YAML'} = 0;
eval { set(session => 'YAML') };
like($@, qr/unable to load session engine 'YAML'/,
    "the YAML session engine depends on YAML");

# when present, I CAN HAZ
$mock_loads->{'Dancer::Session::YAML'} = 1;
eval { set(session => 'YAML') };
is($@, '', "the session engine can be set with CGI::Session");

# load an unknown session engine
eval { set(session => 'galactica') };
like $@, qr/unable to load session engine 'galactica'/,
    "Unknown session engine is refused";


# Test we can unmock stuff, too.
mock 'Dancer::Session::YAML'
    => method 'yaml_file'
    => should sub { 'really big shoe' };

is(
    Dancer::Session::YAML::yaml_file(42),
    'really big shoe',
    "Mocked a method successfully..."
);

unmock 'Dancer::Session::YAML' => method 'yaml_file';

like(
  Dancer::Session::YAML::yaml_file(42),  
  qr/42.yml/,
  "Unmocked method, original method works again",
);

