use Test::More import => ['!pass'];
use strict;
use warnings;
use vars '@ARGV';

use Dancer::GetOpt;
use Dancer;

my @tests = (
    { args => ['--port=2345'], 
      expected => sub { setting('port') == 2345 } },
    { args => ['--port', '2345'], expected => sub { setting('port') eq '2345' }},
    { args => ['-p', '2345'], expected => sub { setting('port') eq '2345' }},

    { args => ['--daemon'], expected => sub { setting('daemon') } },
    { args => ['-d'], expected => sub { setting('daemon') } },

    { args => ['--environment=production'], 
      expected => sub { setting('environment') eq 'production' } },

    { args => ['--confdir=/tmp/foo'],
      expected => sub { setting('confdir') eq '/tmp/foo'} },
);

plan tests => scalar(@tests) + 3;

foreach my $test (@tests) {
    @ARGV = @{ $test->{args}};
    Dancer::GetOpt->process_args();
    ok($test->{expected}->(),
        "arg processing looks good for: ".join(' ', @{$test->{args}}));
}

ok(Dancer::GetOpt->print_usage());

# Dancer->import process ARGV
@ARGV = ('--port=1234');
Dancer->import();
is setting('port'), 1234, "->import process ARGV";

# Dancer->import doesn't process ARGV when PLACK_ENV is set (GH#473)
@ARGV = ('--port=4321');
$ENV{PLACK_ENV} = 'development';
Dancer->import();
is setting('port'), 1234, "->import doesn't process ARGV";
