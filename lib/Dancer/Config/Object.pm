package Dancer::Config::Object;

use strict;
use warnings;

use base 'Exporter';
use Carp 'croak';
use Dancer::Exception qw(:all);

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
        unless ('HASH' eq ref $hashref) {
            # should never happen
            raise 'Core::Config' => "Argument to $class must be a hashref";
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
        # match a (more or less) valid identifier
        next unless $key =~ qr/^[[:alpha:]_][[:word:]]*$/;
        my $value = $object->{$key};
        if ( 'HASH' eq ref $value ) {
            $value = hashref_to_object($value);
        }
        elsif ( 'ARRAY' eq ref $value ) {
            foreach (@$value) {
                $_ = 'HASH' eq ref($_) ? hashref_to_object($_) : $_;
            }
        }
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

=head1 NAME

Dancer::Config::Object - Access the config via methods instead of hashrefs

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

 my $some_value = config->{99_bottles};

Hash keys pointing to hash references will in turn have those "objectified",
but arrays will still be returned as array references.

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@cpan.org> and others,
see the AUTHORS file that comes with this distribution for details.

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=head1 SEE ALSO

L<Dancer> and L<Dancer::Config>.

=cut
