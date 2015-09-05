use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;

my $smileys = '☺☺☺';

{
    package MyApp;

    use utf8;
    use Dancer;

    use Encode qw/ decode_utf8 is_utf8 /;

    set charset => 'UTF-8';
    set logger  => 'Capture';

    get '/' => sub {
        my $text = decode_utf8 $smileys;
        debug "is_utf8: " . is_utf8($text);
        debug "text: $text";
        return "$text";
    };
}

use Dancer::Test;

response_status_is '/' => 200;
