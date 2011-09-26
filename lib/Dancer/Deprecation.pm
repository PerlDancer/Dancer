package Dancer::Deprecation;

use strict;
use warnings;
use Carp qw/croak carp/;

sub deprecated {
    my ($class, %args) = @_;

    my ( $package, undef, undef, $sub ) = caller(1);

    unless ( defined $args{feature} ) {
        $args{feature} = $sub;
    }

    my $deprecated_at = defined $args{version} ? $args{version} : undef;

    my $msg;
    if ( defined $args{message} ) {
        $msg = $args{message};
    }
    else {
        $msg = "$args{feature} has been deprecated";
    }
    $msg .= " since version $deprecated_at" if defined $deprecated_at;
    $msg .= ". " . $args{reason} if defined $args{reason};

    croak($msg) if $args{fatal};
    carp($msg);
}

1;

=head1 NAME

Dancer::Deprecation - handle deprecation messages

=head1 SYNOPSIS

  Dancer::Deprecation->deprecated(
    feature => 'sub_name',
    version => '1.3000',
    reason  => '...',
  );

=head1 DESCRIPTION

=head2 METHODS

=head3 deprecated

List of possible parameters:

=over 4

=item B<feature> name of the feature to deprecate

=item B<version> from which version the feature is deprecated

=item B<message> message to display

=item B<fatal> if set to true, croak instead of carp

=item B<reason> why is the feature deprecated

=back

You can call the method with no arguments, and a default message using informations from C<caller> will be build for you.

=head1 LICENSE

This module is free software and is distributed under the same terms as Perl
itself.

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@sukria.net>

=head1 SEE ALSO

L<Package::DeprecationManager>

=cut
