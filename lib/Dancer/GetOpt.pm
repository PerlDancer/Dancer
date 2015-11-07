package Dancer::GetOpt;
our $AUTHORITY = 'cpan:SUKRIA';
# ABSTRACT: Process command-line options for Dancer scripts
$Dancer::GetOpt::VERSION = '1.3202';
use strict;
use warnings;

use Dancer::Config 'setting';
use Getopt::Long;
use FindBin;
use File::Spec;

my $options = {
    port        => setting('port'),
    daemon      => setting('daemon'),
    confdir     => setting('confdir') || setting('appdir'),
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
        'confdir=s'     => sub { arg_to_setting(@_) },
    ) || usage_and_exit();

    usage_and_exit() if $help;
}

sub usage_and_exit { print_usage() && exit(0) }

sub print_usage {
    my $app = File::Spec->catfile( $FindBin::RealBin, $FindBin::RealScript );
    print <<EOF
\$ $app [options]

 Options:
   --daemon             Run in background (false)
   --port=XXXX          Port number to bind to (3000)
   --confdir=PATH       Path the config dir (appdir if not specified)
   --environment=ENV    Environment to use (development)
   --help               Display usage information

OPTIONS

--daemon

When this flag is set, the Dancer script will detach from the terminal and will
run in background. This is perfect for production environment but is not handy
during the development phase.

--port=XXXX

This lets you change the port number to use when running the process. By
default, the port 3000 will be used.

--confdir=PATH

By default, Dancer looks in the appdir for config files (config.yml and
environments files). You can change this with specifying an alternate path to
the configdir option.

Dancer will then look in that directory for a file config.yml and the
appropriate environement configuration file.

If not specified, confdir points to appdir.

--environment=ENV

Which environment to use. By default this value is set to development.


EOF
}

'Dancer::GetOpt';

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::GetOpt - Process command-line options for Dancer scripts

=head1 VERSION

version 1.3202

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
