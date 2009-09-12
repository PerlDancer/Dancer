package Dancer::PlackAdapter;
use strict;

sub new {
    my($class, $app) = @_;
    bless { app => $app }, $class;
}

sub handler {
    my $self = shift;
    return sub {
        my $env = shift;
        $CGI::PSGI = 1;
        Dancer->run(CGI->new($env));
    };
}

1;
