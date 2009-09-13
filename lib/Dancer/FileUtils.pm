package Dancer::FileUtils;

use strict;
use warnings;

use File::Basename ();
use File::Spec;

use base 'Exporter';
use vars '@EXPORT_OK';

@EXPORT_OK = qw(path dirname read_file_content read_glob_content);

sub path { File::Spec->catfile(@_) }
sub dirname { File::Basename::dirname(@_) }

sub read_file_content {
    my ($file) = @_;
    my $fh;
    if (open($fh, '<', $file)) {
        return read_glob_content($fh);
    }
    else {
        return undef;
    }
}

sub read_glob_content {
    my ($fh) = @_;    
    binmode $fh;
    my @content = <$fh>;
    close $fh;
    return join("", @content);
}

'Dancer::FileUtils';
