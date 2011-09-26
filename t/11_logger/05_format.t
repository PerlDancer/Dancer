use strict;
use warnings;
use Test::More;
use Dancer::Config qw/setting/;
use Dancer::Logger::File;
use Dancer::Request;

plan tests => 9;

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

setting logger_format => '%m %{%H:%M}t';
$str = $l->format_message('debug', 'this is debug');
like $str, qr/this is debug \[\d\d:\d\d\]/;

setting charset => 'UTF-8', logger_format => '%h %t %T';
$str = $l->format_message('debug', 'this is debug');
like $str, qr{- \s
              \d+/[^/]+/\d+ \s \d+:\d+:\d+ \s
              \d+-\d+-\d+ \s \d+:\d+:\d+ }xi;


my $env = {
    'psgi.url_scheme' => 'http',
    REQUEST_METHOD    => 'GET',
    SCRIPT_NAME       => '/foo',
    PATH_INFO         => '/bar/baz',
    REQUEST_URI       => '/foo/bar/baz',
    QUERY_STRING      => '',
    SERVER_NAME       => 'localhost',
    SERVER_PORT       => 5000,
    SERVER_PROTOCOL   => 'HTTP/1.1',
    HTTP_ACCEPT_TYPE  => 'text/html',
};

my $headers = HTTP::Headers->new();
$headers->header('Accept-Type' => 'text/html');

my $request = Dancer::Request->new(env => $env);
$request->{headers} = $headers;

Dancer::SharedData->request($request);

setting logger_format => '[%{accept_type}h] %m';
$str = $l->format_message('debug', 'this is debug');
like $str, qr/\[text\/html\] this is debug/;

my $warn;
do {
    local $SIG{__WARN__} = sub { $warn = $_[0] };
    setting logger_format => '%y';
    $str = $l->format_message('debug', 'this is sparta');
};
like $warn, qr/%y not supported/;
