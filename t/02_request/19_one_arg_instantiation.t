use Test::More tests => 1;
use Test::Exception;

use Dancer::Request;

my $env = {};
my $expected = qr/Attempt to instantiate a request object with a single argument/;
throws_ok {Dancer::Request->new($env);} $expected, "Provides good errors about old usage syntax";
