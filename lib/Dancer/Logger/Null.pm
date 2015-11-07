package Dancer::Logger::Null;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: blackhole-like silent logging engine for Dancer
$Dancer::Logger::Null::VERSION = '1.3202';
use strict;
use warnings;
use base 'Dancer::Logger::Abstract';

sub _log {1}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Logger::Null - blackhole-like silent logging engine for Dancer

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

=head1 DESCRIPTION

This logger acts as a blackhole (or /dev/null, if you will) that discards all
the log messages instead of displaying them anywhere.

=head1 METHODS

=head2 _log

Discards the message.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
