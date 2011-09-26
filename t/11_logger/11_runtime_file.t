use strict;
use warnings;

use Test::More import => ['!pass'];

use Dancer;
use Dancer::FileUtils;
use Dancer::Test;

plan skip_all => "File::Temp 0.22 required"
    unless Dancer::ModuleLoader->load( 'File::Temp', '0.22' );

plan tests => 3;

my $dir = File::Temp::tempdir(CLEANUP => 1, TMPDIR => 1);
my $logfile = Dancer::FileUtils::path($dir, "logs", "development.log");

set(environment => 'development',
    appdir      => $dir,
    log         => 'debug',
    logger      => 'file');


get '/' => sub {
    die "Dieing in route handler - arrggghh!";
};

response_status_is [GET => '/'], 500 => "We get a 500 answer";
ok -f $logfile => "Log file got created";

my $logcontents = Dancer::FileUtils::read_file_content($logfile);

like $logcontents => qr/arrggghh!/ => "Log file includes die message";
