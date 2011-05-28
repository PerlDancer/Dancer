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
    Dancer::Plugin::Auth::Twitter
    Dancer::Plugin::DBIC
    Dancer::Plugin::Database
    Dancer::Plugin::FlashMessage
    Dancer::Plugin::MobileDevice
    Dancer::Plugin::REST
    Dancer::Session::Cookie
    Dancer::Session::Storable
);

# install them in your perlbrew first
if ($ENV{CPANM_RUN}) {
    `cpanm -n --quiet $_` for @modules ;
}

plan tests => scalar(@modules);
Test::DependentModules::test_module($_) for @modules; 

