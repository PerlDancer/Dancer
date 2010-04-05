package Dancer::Logger::Abstract;

use strict;
use warnings;
use base 'Dancer::Engine';

use Dancer::SharedData;
use Dancer::Timer;
use Dancer::Config 'setting';

# This is the only method to implement if logger engines.
# It receives the following arguments:
# $msg_level, $msg_content, it gets called only if the configuration allows
# a message of the given level to be logged.
sub _log { die "_log not implemented" }

sub _should {
    my ($self, $msg_level) = @_;
    my $conf_level = setting('log') || 'debug';
    my $levels = {
        # levels < 0 are for core only
        core    => -10, 

        # levels > 0 are for end-users only
        debug   => 1,
        warning => 2,
        error   => 3,
    };
    return $levels->{$conf_level} <= $levels->{$msg_level};
}

sub format_message {
    my ($self, $level, $message) = @_;
    my ($package, $file, $line) = caller(4);
    $package ||= '-';
    $file    ||= '-';
    $line    ||= '-';

    my $time = Dancer::SharedData->timer->to_string();
    chomp $message;
    return "$time [$$] ($level) $message in $file l. $line\n";
}

sub core    { $_[0]->_should('core')    and $_[0]->_log('core' ,   $_[1]) }
sub debug   { $_[0]->_should('debug')   and $_[0]->_log('debug',   $_[1]) }
sub warning { $_[0]->_should('warning') and $_[0]->_log('warning', $_[1]) }
sub error   { $_[0]->_should('error')   and $_[0]->_log('error',   $_[1]) }

1;
