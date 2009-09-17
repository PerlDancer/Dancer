use CGI::PSGI;
use webapp;

sub {
    my $env = shift;
    local *ENV = $env;
    Dancer->run(CGI->new);
};
