use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer::Logger::File;
use Dancer ':syntax';
use Dancer::Test;
use Dancer::Exception ':all';

plan skip_all => "File::Temp 0.22 required"
    unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );

my $dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
my $logfile= "$dir/logs/test.log";

set warnings => 1; # we want to test fatal warnings
set log => 'fatal';
set logger => 'null'; # we'll monkeypatch later
set views => path( 't', '25_exceptions', 'views' );

use vars qw(@log_messages);

{
    no warnings 'redefine';
    local *Dancer::Logger::Null::_log = sub { shift; push @log_messages, $_[1] };
    # raise a (now fatal) warning in the route handler
    get '/raise_in_hook' => sub {
        warn "Boom";
        template 'index', { foo => 'baz5' };
    };
    route_exists [ GET => '/raise_in_hook' ];
    response_status_is( [ GET => '/raise_in_hook' ], 500 => "Internal error due to warning");
    response_content_like( [ GET => '/raise_in_hook' ], qr|Error 500| );
    
    # Now, check that we find the error in the log
    my @error= grep {m!request to GET /raise_in_hook crashed!} @log_messages;
    is 0+@error, 2, "We logged the fatal warning to the logger (two calls)";
}

done_testing();

