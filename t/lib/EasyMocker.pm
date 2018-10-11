package EasyMocker;
# I want an easy to use mocker, with pretty explicit syntax

use strict;
use warnings;

use vars qw(@EXPORT);
use base 'Exporter';

@EXPORT = qw(mock unmock should method);

# syntax:
# use t::lib::EasyMocker;
# mock 'My::Class::method' => with sub { };
# or even
# mock 'My::Class', 'method' => with sub { };

sub method { @_ }
sub should { @_ }

my $MOCKS = {};
my %orig_coderef;
sub mock {
    { 
        no strict 'refs'; 
        no warnings 'redefine', 'prototype';
        if (@_ == 3) {
            my ($class, $method, $sub) = @_;
            $orig_coderef{"${class}::${method}"}
                = \&{ *{"${class}::${method}"} };
            *{"${class}::${method}"} = $sub;
        }
        else {
            my ($method, $sub) = @_;
            $orig_coderef{$method} = \&$method;
            *$method = $sub;
        }
    }
}

sub unmock {
    {
        no strict 'refs';
        no warnings 'redefine', 'prototype';
        if (@_ == 2) {
            my ($class, $method) = @_;
            if (!defined $orig_coderef{"${class}::${method}"}) {
                die "Can't unmock ${class}::${method} "
                    . "- it wasn't mocked?";
            }
            *{"${class}::${method}"} = 
                delete $orig_coderef{"${class}::${method}"};
        } else {
            my ($method) = @_;
            *$method = $orig_coderef{$method};
        }
    }
}
1;
