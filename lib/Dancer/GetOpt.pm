package Dancer::GetOpt;

use strict;
use warnings;

use Dancer::Config 'setting';
use Getopt::Long;

my $options = {
    port        => setting('port'),
    daemon      => setting('daemon'),
    environment => 'development',
};

sub arg_to_setting {
    my ($option, $value) = @_;
    setting($option => $value);
}

sub process_args {
    my $help = 0;
    GetOptions(
        'help'          => \$help,
        'port=i'        => sub { arg_to_setting(@_) },
        'daemon'        => sub { arg_to_setting(@_) },
        'environment=s' => sub { arg_to_setting(@_) },
    ) || usage_and_exit();

    usage_and_exit() if $help;
}

sub usage_and_exit { print_usage() && exit(0) }

sub print_usage {
    print <<EOF
\$ ./yourdancerapp.pl [options]

 Options:
   --daemon             Run in background (false)
   --port=XXXX          Port number to bind to (3000)
   --environment=ENV    Environement to use (development)
   --help               Display usage information

OPTIONS

--daemon

When this flag is set, the Dancer script will detach from the terminal and will
run in background. This is perfect for production environment but is not handy
during the development phase.

--port=XXXX

This lets you change the port number to use when running the process. By
default, the port 3000 will be used.

--environment=ENV

THIS OPTIONS IS NOT SUPPORTED YET 

EOF
}

'Dancer::GetOpt';
