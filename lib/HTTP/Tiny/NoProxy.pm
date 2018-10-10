package HTTP::Tiny::NoProxy;

use base 'HTTP::Tiny';

# Simple subclass of HTTP::Tiny, adding the no_proxy argument, because we're
# talking to 127.0.0.1 and it makes no sense to use a proxy for that - and
# causes lots of cpantesters failures on any boxes that have proxy env vars set.
#
# See https://github.com/chansen/p5-http-tiny/pull/118 for a PR I raised for
# HTTP::Tiny to automatically ignore proxy settings for 127.0.0.1/localhost.


sub new {
    my ($self, %args) = @_;

    $args{no_proxy} = "127.0.0.1";

    return $self->SUPER::new(%args);
}


1;
