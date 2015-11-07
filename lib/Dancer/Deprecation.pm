package Dancer::Deprecation;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: handle deprecation messages
$Dancer::Deprecation::VERSION = '1.3202';
use strict;
use warnings;
use Carp;
use Dancer::Exception qw(:all);

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

    raise core_deprecation => $msg if $args{fatal};
    carp($msg);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Deprecation - handle deprecation messages

=head1 VERSION

version 1.3202

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

=item B<fatal> if set to true, raises a Dancer::Exception (Core::Deprecation) instead of carp

=item B<reason> why is the feature deprecated

=back

You can call the method with no arguments, and a default message using information from C<caller> will be built for you.

=head1 LICENSE

This module is free software and is distributed under the same terms as Perl
itself.

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@sukria.net>

=head1 SEE ALSO

L<Package::DeprecationManager>

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
