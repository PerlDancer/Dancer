use CGI::PSGI;
use webapp;

sub {
    my $env = shift;
    Dancer->run(CGI::PSGI->new($env));
};
