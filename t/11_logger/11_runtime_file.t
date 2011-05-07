use strict;
use warnings;

use File::Temp qw/tempdir/;
use Test::More tests => 3, import => ['!pass'];

use Dancer;
use Dancer::FileUtils;
use Dancer::Test;

my $dir = tempdir(CLEANUP => 1, TMPDIR => 1);
my $logfile = Dancer::FileUtils::path($dir, "logs", "development.log");

set environment => 'development';
set appdir => $dir;

set log    => 'debug';
set logger => 'file';


get '/' => sub {
    die "Dieing in route handler - arrggghh!";
};

response_status_is [GET => '/'], 500 => "We get a 500 answer";
ok -f $logfile => "Log file got created";

my $logcontents = Dancer::FileUtils::read_file_content($logfile);

like $logcontents => qr/arrggghh!/ => "Log file includes die message";
