use CGI::PSGI;
use webapp;

use Dancer::Config 'setting';
setting( middleware => 'PSGI' );

sub {
    my $env = shift;
    local *ENV = $env;
    Dancer->run(CGI->new);
};
