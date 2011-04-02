package TestUtils;

use base 'Exporter';
use vars '@EXPORT';

use File::Path qw(mkpath rmtree);
use Dancer::Request;

@EXPORT =
  qw(write_file clean_tmp_files);

sub write_file {
    my ($file, $content) = @_;

    open CONF, '>', $file or die "cannot write file $file : $!";
    print CONF $content;
    close CONF;
}

sub clean_tmp_files {
    my $appdir = setting('appdir') || File::Spec->tmpdir();
    my $logs_dir = File::Spec->catdir($appdir, 'logs');
    rmtree($logs_dir) if -d $logs_dir;

    my $sessions = setting session_dir;
    rmtree($sessions) if $sessions && -d $sessions;
}

1;
