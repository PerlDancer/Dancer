package Dancer::FileUtils;

use strict;
use warnings;

use File::Basename ();
use File::Spec;

use base 'Exporter';
use vars '@EXPORT_OK';

@EXPORT_OK = qw(path dirname read_file_content);

sub path { File::Spec->catfile(@_) }
sub dirname { File::Basename::dirname(@_) }

sub read_file_content {
    my ($file) = @_;
    my $content = '';

    if (open(FILE_TO_READ, '<', $file)) {
        binmode FILE_TO_READ;
        my $buffer;
        while (read(FILE_TO_READ, $buffer, 8192)) {
            $content .= $buffer;
        }
        close FILE_TO_READ;
        return $content;
    }
    else {
        return undef;
    }
}

'Dancer::FileUtils';
