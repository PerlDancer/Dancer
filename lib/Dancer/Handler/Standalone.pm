package Dancer::Handler::Standalone;
# ABSTRACT: standalone HTTP server frontend for Dancer

=head1 DESCRIPTION

A standalone HTTP server handler. Great for debugging.

=cut

use strict;
use warnings;

use HTTP::Server::Simple::PSGI;
use base 'Dancer::Handler', 'HTTP::Server::Simple::PSGI';

use Dancer::HTTP;
use Dancer::GetOpt;
use Dancer::Config 'setting';
use Dancer::FileUtils qw(read_glob_content);
use Dancer::SharedData;

=method start

When in standalone mode, this method initializes the process and start
an HTTP server.

=cut
sub start {
    my $self = shift;

    my $ipaddr = setting('server');
    my $port   = setting('port');
    my $dancer = Dancer::Handler::Standalone->new($port);
    $dancer->host($ipaddr);

    my $app = $self->psgi_app();

    $dancer->app($app);

    if (setting('daemon')) {
        my $pid = $dancer->background();
        _print_startup_info($pid);
        return $pid;
    }
    else {
        _print_startup_info($$);
        $dancer->run();
    }
}

sub _print_startup_info {
    my $pid    = shift;
    my $ipaddr = setting('server');
    my $port   = setting('port');

    # we only print the info if we need to
    setting('startup_info') or return;

    # bare minimum
    print STDERR ">> Dancer $Dancer::VERSION server $pid listening " .
                 "on http://$ipaddr:$port\n";

    # all loaded plugins
    foreach my $module ( grep { $_ =~ m{^Dancer/Plugin/} } keys %INC ) {
        $module =~ s{/}{::}g;  # change / to ::
        $module =~ s{\.pm$}{}; # remove .pm at the end

        my $version = $module->VERSION;
        print ">> $module ($version)\n";
    }

}

1;
