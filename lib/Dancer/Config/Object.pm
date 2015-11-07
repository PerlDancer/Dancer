package Dancer::Config::Object;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: Access the config via methods instead of hashrefs
$Dancer::Config::Object::VERSION = '1.3202';
use strict;
use warnings;

use base 'Exporter';
use Carp 'croak';
use Dancer::Exception qw(:all);
use Scalar::Util 'blessed';

register_exception('BadConfigMethod',
    message_pattern =>
      qq{Can't locate config attribute "%s".\nAvailable attributes: %s});

our @EXPORT_OK = qw(hashref_to_object);

{
    my $index = 1;

    sub hashref_to_object {
        my ($hashref) = @_;
        my $class = __PACKAGE__;
        my $target = "${class}::__ANON__$index";
        $index++;
        if ('HASH' ne ref $hashref) {
            if ( blessed $hashref ) {
                # we have already converted this to an object. This can happen
                # in cases where Dancer::Config->load is called more than
                # once.
                return $hashref;
            }
            else {
                # should never happen
                raise 'Core::Config' => "Argument to $class must be a hashref";
            }
        }
        my $object = bless $hashref => $target;
        _add_methods($object);

        return $object;
    }
}


sub _add_methods {
    my ($object) = @_;
    my $target = ref $object;

    foreach my $key ( keys %$object ) {
        my $value = $object->{$key};
        if ( 'HASH' eq ref $value ) {
            $value = hashref_to_object($value);
        }
        elsif ( 'ARRAY' eq ref $value ) {
            foreach (@$value) {
                $_ = 'HASH' eq ref($_) ? hashref_to_object($_) : $_;
            }
        }

        # match a (more or less) valid identifier
        next unless $key =~ qr/^[[:alpha:]_][[:word:]]*$/;
        my $method = "${target}::$key";
        no strict 'refs';
        *$method = sub {$value};
    }
    _setup_bad_method_trap($target);
}

# AUTOLOAD will only be called if a non-existent method is called. It's used
# to generate the list of available methods. It's slow, but we're going to
# die. Who wants to die quickly?
sub _setup_bad_method_trap {
    my ($target) = @_;
    no strict;    ## no critic (ProhibitNoStrict)
    *{"${target}::AUTOLOAD"} = sub {
        $AUTOLOAD =~ /.*::(.*)$/;

        # should never happen
        my $bad_method = $1    ## no critic (ProhibitCaptureWithoutTest)
          or croak "Could not determine method called via $AUTOLOAD";
        return if 'DESTROY' eq $bad_method;
        my $symbol_table = "${target}::";

        # In these fake classes, we only have methods
        my $methods =
          join ', ' => grep { !/^(?:AUTOLOAD|DESTROY|$bad_method)$/ }
          sort keys %$symbol_table;
        raise BadConfigMethod => $bad_method, $methods;
    };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dancer::Config::Object - Access the config via methods instead of hashrefs

=head1 VERSION

version 1.3202

=head1 DESCRIPTION

If C<strict_config> is set to a true value in the configuration, the
C<config()> subroutine will return an object instead of a hashref. Instead of
this:

 my $serializer = config->{serializer};
 my $username   = config->{auth}{username};

You get this:

 my $serializer = config->serializer;
 my $username   = config->auth->username;

This helps to prevent typos. If you mistype a configuration name:

 my $pass = config->auth->pass;

An exception will be thrown, tell you it can't find the method name, but
listing available methods:

 Can't locate config attribute "pass".
 Available attributes: password, username

If the hash key cannot be converted into a proper method name, you can still
access it via a hash reference:

 my $some_value = config->{'99_bottles'};

And call methods on it, if possible:

 my $sadness = config->{'99_more_bottles'}->last_bottle;

Hash keys pointing to hash references will in turn have those "objectified".
Arrays will still be returned as array references. However, hashrefs inside of
the array refs may still have their keys allowed as methods:

 my $some_value = config->some_list->[1]->host;

=head1 METHOD NAME DEFINITION

We use the following regular expression to determine if a hash key qualifies
as a method:

 /^[[:alpha:]_][[:word:]]*$/;

Note that this means C<naïve> (note the dots over the i) can be a method name,
but unless you C<use utf8;> to declare that your source code is UTF-8, you may
have disappointing results calling C<< config->naïve >>. Further, depending on
your version of Perl and the software to read your config file ... well, you
get the idea. We recommend sticking with ASCII identifiers if you wish your
code to be portable.

Patches/suggestions welcome.

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@cpan.org> and others,
see the AUTHORS file that comes with this distribution for details.

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=head1 SEE ALSO

L<Dancer> and L<Dancer::Config>.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
