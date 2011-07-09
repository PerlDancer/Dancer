use strict;
use warnings;
use Test::More import => ['!pass'];
use Dancer ':syntax';

plan tests => 1;

# This isn't really a test, but simply to produce some diagnosis output showing
# the versions of various modules in one place.  Some modules, e.g. Test::TCP,
# aren't a dependency, we simply skip tests if it's not available, so if it is
# available, we don't get told the version in the test report.

my @modules = qw(
    Test::TCP
    Test::More
    JSON
	YAML
    Clone
    Plack
    XML::Simple
    HTTP::Parser::XS
);

for my $module (@modules) {
    # Just in case this fails for any modules for any reason, catch errors:
    eval {
        if (Dancer::ModuleLoader->load($module)) { 
            my $version = $module->VERSION;
            diag("$module $version loaded successfully");
        } else {
            diag("$module is not available");
        }
    };
    if ($@) {
        diag("Error while checking $module version - $@");
    }
}


ok(1, "Done checking versions of optional modules");

