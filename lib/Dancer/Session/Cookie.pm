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
