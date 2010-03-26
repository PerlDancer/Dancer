package Dancer::Plugin;
use strict;
use warnings;

use base 'Exporter';
use vars qw(@EXPORT);

@EXPORT = qw(
    register
    register_plugin
);

my $_keywords = [];

sub register($$) {
    my ($keyword, $code) = @_;
    push @$_keywords, {$keyword => $code};
}

sub register_plugin {
    my ($plugin) = caller();
    my ($application) = caller(1);

    for my $keyword (@$_keywords) {
        my ($name, $code) = each (%$keyword);
        {   
            no strict 'refs';
            *{"${application}::${name}"} = $code;
        }
    }
}

1;
