package Dancer::FileUtils;

use strict;
use warnings;

use File::Basename ();
use File::Spec;

use base 'Exporter';
use vars '@EXPORT_OK';

@EXPORT_OK = qw(path dirname dump_file_content);

sub path { File::Spec->catfile(@_) }
sub dirname { File::Basename::dirname(@_) }

sub dump_file_content {
    my ($file) = @_;
    if (open(FILE_TO_READ, '<', $file)) {
        binmode FILE_TO_READ;
        my $buffer;
        while (read(FILE_TO_READ, $buffer, 8192)) {
            print $buffer;
        }
        close FILE_TO_READ;
    }
    else {
        return undef;
    }
}

'Dancer::FileUtils';
