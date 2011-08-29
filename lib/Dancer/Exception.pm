package Dancer::Exception;

use strict;
use warnings;
use Carp;

use Dancer::Exception::Base;

use base qw(Exporter);

our @EXPORT_OK = (qw(try catch continuation register_exception registered_exceptions raise));
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use Try::Tiny ();

sub try (&;@) {
    goto &Try::Tiny::try;
}

sub catch (&;@) {
	my ( $block, @rest ) = @_;

    my $continuation_code;
    my @new_rest = grep { ref ne 'Try::Tiny::Catch' or $continuation_code = $$_, 0 } @rest;
    $continuation_code
      and return ( bless( \ sub {
          ref && $_->isa('Dancer::Continuation')
            ? $continuation_code->(@_) : $block->(@_);
      },  'Try::Tiny::Catch') , @new_rest);

    return ( bless ( \ sub {
          ref && $_->isa('Dancer::Continuation')
            ? die($_) : $block->(@_) ;
      }, 'Try::Tiny::Catch'), @new_rest );
}

sub continuation (&;@) {
	my ( $block, @rest ) = @_;

    my $catch_code;
    my @new_rest = grep { ref ne 'Try::Tiny::Catch' or $catch_code = $$_, 0 } @rest;
    $catch_code 
      and return ( bless( \ sub {
          ref && $_->isa('Dancer::Continuation')
            ? $block->(@_) : $catch_code->(@_);
      },  'Try::Tiny::Catch') , @new_rest);

    return ( bless ( \ sub {
          ref && $_->isa('Dancer::Continuation')
            ? $block->(@_) : die($_);
      }, 'Try::Tiny::Catch'), @new_rest );
}

sub raise ($;@) {
    my $exception_name = shift;
    my $exception = "Dancer::Exception::$exception_name"->new(@_);
    $exception->throw();
}

sub register_exception {
    my ($exception_name, %params) = @_;
    my $exception_class = 'Dancer::Exception::' . $exception_name;
    my $path = $exception_class; $path =~ s|::|/|g; $path .= '.pm';

    if (exists $INC{$path}) {
        local $Carp::CarpLevel = $Carp::CarpLevel++;
        'Dancer::Exception::Base::Internal'
            ->new("register_exception failed: $exception_name is already defined")
            ->throw;
    }

    my $message_pattern = $params{message_pattern};
    my $composed_from = $params{composed_from};
    my @composition = map { 'Dancer::Exception::' . $_ } @$composed_from;

    $INC{$path} = __FILE__;
    eval "\@${exception_class}::ISA=qw(Dancer::Exception::Base " . join (' ', @composition) . ');';

    if (defined $message_pattern) {
        no strict 'refs';
        *{"${exception_class}::_message_pattern"} = sub { $message_pattern };
    }

}

sub registered_exceptions {
    sort map { s|/|::|g; s/\.pm$//; $_ } grep { s|^Dancer/Exception/||; } keys %INC;
}

register_exception(@$_) foreach (
    ['Core', message_pattern => 'core - %s'],
    ['Fatal', message_pattern => 'fatal - %s'],
    ['Internal', message_pattern => 'internal - %s'],
);

1;
