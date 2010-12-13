use strict;
use warnings;
use Test::More;
use Dancer::Config qw/setting/;
use Dancer::Logger::File;

plan tests => 5;

setting logger_format => '(%L) %m';
my $l = Dancer::Logger::File->new;
ok my $str = $l->format_message( 'debug', 'this is debug' );
is $str, "(debug) this is debug\n";

# custom format
my $fmt = $l->_log_format();
is $fmt, '(%L) %m';

# no log format defined
setting logger_format => undef;
$fmt = $l->_log_format();
is $fmt, '[%P] %L @%D> %i%m in %f l. %l';

# log format from preset
setting logger_format => 'simple';
$fmt = $l->_log_format();
is $fmt, '[%P] %L @%D> %i%m in %f l. %l';
