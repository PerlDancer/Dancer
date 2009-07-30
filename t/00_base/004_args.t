use Test::More import => ['!pass'];
use strict;
use warnings;
use vars '@ARGV';

use Dancer::GetOpt;
use Dancer::Config 'setting';

my @tests = (
    
    { args => ['--port=2345'], 
      expected => sub { setting('port') == 2345 } },
    { args => ['--port', '2345'], expected => sub { setting('port') eq '2345' }},
    { args => ['-p', '2345'], expected => sub { setting('port') eq '2345' }},

    { args => ['--daemon'], expected => sub { setting('daemon') } },
    { args => ['-d'], expected => sub { setting('daemon') } },

    { args => ['--environment=production'], 
      expected => sub { setting('environment') eq 'production' } },
);

plan tests => scalar(@tests);

foreach my $test (@tests) {
    @ARGV = @{ $test->{args}};
    Dancer::GetOpt->process_args();
    ok($test->{expected}->(),
        "arg processing looks good for: ".join(' ', @{$test->{args}}));
}
