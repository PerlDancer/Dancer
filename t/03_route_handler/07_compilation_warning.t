use Test::More import => ['!pass'];

use Dancer ':syntax';
use Dancer::Test;
use Dancer::Logger;
use File::Temp qw/tempdir/;

my $dir = tempdir(CLEANUP => 1, TMPDIR => 1);
set appdir => $dir;
Dancer::Logger->init('File');

# perl <= 5.8.x won't catch the warning
plan skip_all => 'Need perl >= 5.10' if $] < 5.010;

set warnings => 1;
set show_errors => 1;

get '/warning' => sub {
    my $bar;
	"$bar foo";
};

my @tests = (
    { path => '/warning', 
	  expected => qr/Use of uninitialized value \$bar in concatenation/},
);

plan tests => scalar(@tests);

foreach my $test (@tests) {
    response_content_like [GET => $test->{path}] => $test->{expected},
      "response looks good for ".$test->{path};
}

Dancer::Logger::logger->{fh}->close;
File::Temp::cleanup();
