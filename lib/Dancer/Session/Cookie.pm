package Dancer::Session::Cookie;

use strict;
use warnings;
use base 'Dancer::Session::Abstract';

use Dancer::Config 'setting';
use Dancer::ModuleLoader;
use Storable;

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

    #die "SES: " . setting("memcached_servers");
    #die Dumper(Dancer::Config::settings);

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

    Dancer::Logger->debug("Cookie session retrieve $id");

    # 1. decrypt and deserialize $id
    my $plain_text = _decrypt($id);

    # 2. deserialize
    my $ses = $class->new($plain_text && thaw($plain_text));

    use Data::Dumper;
    Dancer::Logger->debug("Cookie session retrieved: " .
        Dumper($ses));

    return $ses;
}

sub create {
    my $class = shift;
    Dancer::Logger->debug('Cookie session created');
    return $class->new(id => 'empty session');
}

sub flush {
    my $self = shift;
    use Data::Dumper;
    Dancer::Logger->debug('Cookie session flushed ' . Dumper($self));

    # 1. serialize and encrypt session
    delete $self->{id};
    my $cipher_text = _encrypt(freeze $self);

    Dancer::Logger->debug("Cookie session serialized into: $cipher_text");

    my $SESSION_NAME = 'dancer.session';
    Dancer::Cookies->cookies->{$SESSION_NAME} = Dancer::Cookie->new(
        name  => $SESSION_NAME,
        value => $cipher_text,
    );
    return 1;
}

sub destroy {
    Dancer::Logger->debug('Cookie session deleted');

    my $SESSION_NAME = 'dancer.session';
    delete Dancer::Cookies->cookies->{$SESSION_NAME};

    return 1;
}

sub _encrypt {
    my $plain_text = shift;

    my $crc32 = String::CRC32::crc32($plain_text);

    my $res = MIME::Base64::encode($CIPHER->encrypt(pack('L', $crc32) . $plain_text));
    $res =~ tr{=+/}{_*-};   # cookie-safe Base64

    return $res;
}

sub _decrypt {
    my $cookie = shift;

    $cookie =~ tr{_*-}{=+/};
    my ($crc32, $cipher_text) = unpack "La*", MIME::Base64::decode($cookie);

    my $plain_text = $CIPHER->decrypt($cipher_text);
    return $crc32 == String::CRC32::crc32($plain_text) ? $plain_text : undef;
}

1;
