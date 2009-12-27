package Dancer::Session::Cookie;

use strict;
use warnings;
use base 'Dancer::Session::Abstract';

use Dancer::Config 'setting';
use Dancer::ModuleLoader;
use Storable ();
use MIME::Base64 ();

# crydec
my $CIPHER = undef;

sub init {
    my ($class) = @_;

    Dancer::ModuleLoader->load('Crypt::CBC')
        or die "Crypt::CBC is needed and is not installed";

    Dancer::ModuleLoader->load('String::CRC32')
        or die "String::CRC32 is needed and is not installed";

    Dancer::ModuleLoader->load('Crypt::Rijndael')   # XXX fallback to DES
        or die "Crypt::Rijndael is needed and is not installed";

    my $key = setting("session_cookie_key")     # XXX default to smth with warning
        or die "The setting session_cookie_key must be defined";

    $CIPHER = Crypt::CBC->new(
        -key    => $key,
        -cipher => 'Rijndael',
    );
}

sub new {
    my $self = Dancer::Object::new(@_); 
    # id is not needed here because the whole serialized session is
    # the "id"
    return $self;
}

sub retrieve {
    my ($class, $id) = @_;

    my $ses = 
        eval {
            # 1. decrypt and deserialize $id
            my $plain_text = _decrypt($id);

            # 2. deserialize
            $plain_text && Storable::thaw($plain_text);
        }
    || $class->new();

    return $ses;
}

sub create {
    my $class = shift;
    return $class->new(id => 'empty session');
}

sub flush {
    my $self = shift;

    # 1. serialize and encrypt session
    delete $self->{id};
    my $cipher_text = _encrypt(Storable::freeze($self));

    my $SESSION_NAME = 'dancer.session';
    Dancer::Cookies->cookies->{$SESSION_NAME} = Dancer::Cookie->new(
        name  => $SESSION_NAME,
        value => $cipher_text,
    );
    return 1;
}

sub destroy {
    my $SESSION_NAME = 'dancer.session';
    delete Dancer::Cookies->cookies->{$SESSION_NAME};

    return 1;
}

sub _encrypt {
    my $plain_text = shift;

    my $crc32 = String::CRC32::crc32($plain_text);

    # XXX should gzip data if it grows too big. CRC32 won't be needed
    # then.
    my $res = MIME::Base64::encode($CIPHER->encrypt(pack('La*', $crc32, $plain_text)), q{});
    $res =~ tr{=+/}{_*-};   # cookie-safe Base64

    return $res;
}

sub _decrypt {
    my $cookie = shift;

    $cookie =~ tr{_*-}{=+/};

    my ($crc32, $plain_text) = unpack "La*", $CIPHER->decrypt(MIME::Base64::decode($cookie));
    return $crc32 == String::CRC32::crc32($plain_text) ? $plain_text : undef;
}

1;
__END__
=pod

=head1 NAME

Dancer::Session::Cookie - Encrypted cookie-based session backend for Dancer

=head1 DESCRIPTION

This module implements a session engine for sessions stored entirely
inside cookies. Usually only Q<session id> is stored in cookies and
the session data itself is saved in some external storage like
database. This module allows us to avoid using external storage at
all.

Since we cannot trust any data provided by client in cookies, we use
cryptography to ensure secrecy and integrity.

=head1 CONFIGURATION

The setting B<session> should be set to C<cookie> in order to use this session
engine in a Dancer application.

A mandatory setting is needed as well: B<session_cookie_key>, which should
contain a random string of at least 16 characters (shorter keys are
not cryptographically strong using AES in CBC mode).

Here is an example configuration that uses this session engine:

    session: "cookie"
    session_cookie_key: "kjsdf07234hjf0sdkflj12*&(@*jk"

=head1 DEPENDENCY

This module depends on L<Crypt::CBC>, L<Crypt::Rijndael>,
L<String::CRC32>, L<Storable> and L<MIME::Base64>.

=head1 AUTHOR

This module has been written by Alex Kapranoff, see the AUTHORS file for
details.

=head1 SEE ALSO

See L<Dancer::Session> for details about session usage in route handlers.

=head1 COPYRIGHT

This module is copyright (c) 2009 Alex Kapranoff <kappa@cpan.org>.

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=cut
