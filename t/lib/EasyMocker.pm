package EasyMocker;
# I want an easy to use mocker, with pretty explicit syntax

use strict;
use warnings;

use vars qw(@EXPORT);
use base 'Exporter';

@EXPORT = qw(mock should method);

# syntax:
# use t::lib::EasyMocker;
# mock 'My::Class::method' => with sub { };
# or even
# mock 'My::Class', 'method' => with sub { };

sub method { @_ }
sub should { @_ }

my $MOCKS = {};
sub mock {
    { 
        no strict 'refs'; 
        no warnings 'redefine', 'prototype';
        if (@_ == 3) {
            my ($class, $method, $sub) = @_;

            *{"${class}::${method}"} = $sub;
        }
        else {
            my ($method, $sub) = @_;
            *$method = $sub;
        }
    }
}

1;
