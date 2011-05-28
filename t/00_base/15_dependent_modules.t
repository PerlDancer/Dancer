use strict;
use warnings;

use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::DependentModules";
plan skip_all => "Need Test::DependentModules for this test"
  if $@;


my @modules = qw(
    Dancer::Session::Cookie
    Dancer::Session::Storable
    Dancer::Plugin::REST
    Dancer::Plugin::Database
);

plan tests => scalar(@modules);
Test::DependentModules::test_module($_) for @modules; 

