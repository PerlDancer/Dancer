package Dancer::Plugin;
use strict;
use warnings;

use base 'Exporter';
use vars qw(@EXPORT);

@EXPORT = qw(
    register
    register_plugin
);

my @_reserved_keywords = @Dancer::EXPORT;

my $_keywords = [];

sub register($$) {
    my ($keyword, $code) = @_;
    if (grep {$_ eq $keyword} @_reserved_keywords) {
        die "You can't use $keyword, this is a reserved keyword";
    }
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
