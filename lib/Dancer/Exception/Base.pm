package Dancer::Exception::Base;

use strict;
use warnings;
use Carp;

use base qw(Exporter);

use overload '""' => sub { $_[0]->message };
use overload 'cmp' => sub {
    my ($e, $f) = @_;
    ( ref $e && $e->isa(__PACKAGE__)
      ? $e->message : $e )
      cmp
    ( ref $f && $f->isa(__PACKAGE__)
      ? $f->message : $f )
};

# This is the base class of all exceptions

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->_raised_arguments(@_);
    return $self;
}

# base class has a passthrough message
sub _message_pattern { '%s' }

sub throw {
    my $self = shift;
    $self->_raised_arguments(@_);
    die $self;
}

sub rethrow { die $_[0] }

sub message {
    my ($self) = @_;
    my $message_pattern = $self->_message_pattern;
    my $message = sprintf($message_pattern, @{$self->_raised_arguments});
    my @composition = (reverse $self->get_composition);
    shift @composition;
    foreach my $component (@composition) {
        my $class = "Dancer::Exception::$component";
        no strict 'refs';
        my $pattern = $class->_message_pattern;
        $message = sprintf($pattern, $message);
    }
    return $message;
}

sub does {
    my $self = shift;
    my $regexp = join('|', map { '^' . $_ . '$'; } @_);
    (scalar grep { /$regexp/ } $self->get_composition) >= 1;
}

sub get_composition {
    my ($self) = @_;
    my $class = ref($self);
    my @isa = do { no strict 'refs'; @{"${class}::ISA"}, $class };
    return grep { s|^Dancer::Exception::|| } @isa;
}

sub _raised_arguments {
    my $self = shift;
    @_ and $self->{_raised_arguments} = [ @_ ];
    $self->{_raised_arguments};
}

1;
