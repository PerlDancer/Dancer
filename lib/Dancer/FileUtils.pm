package Dancer::FileUtils;

use strict;
use warnings;

use File::Basename ();
use File::Spec;

use base 'Exporter';
use vars '@EXPORT_OK';

@EXPORT_OK = qw(path dirname read_file_content read_glob_content);

sub path    { File::Spec->catfile(@_) }
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

__END__

=pod

=head1 NAME

Dancer::FileUtils - File utilities Dancer uses

=head1 SYNOPSIS

    use Dancer::FileUtils qw/path read_file_content/;

    my $content = read_file_content( path( 'folder', 'folder', 'file' ) );

=head1 DESCRIPTION

Dancer::FileUtils encompasses a few utilities that relate to files which Dancer
uses. Developers may use it instead of writing their own little subroutines or
use additional modules.

=head1 SUBROUTINES/METHODS

=head2 path

    use Dancer::FileUtils 'path';

    my $path = path( 'folder', 'folder', 'filename');

Provides comfortable path resolving, internally using L<File::Spec>.

=head2 dirname

    use Dancer::FileUtils 'dirname';

    my $dir = dirname($path);

Exposes L<File::Basename>'s I<dirname>, to allow fetching a directory name from
a path.

=head2 read_file_content

    use Dancer::FileUtils 'read_file_content';

    my $content = read_file_content($file);

Returns either the content of a file (whose filename is the input) or I<undef>
in case it failed to open the file.

=head2 read_glob_content

    use Dancer::FileUtils 'read_glob_content';

    open my $fh, '<', $file or die "$!\n";
    my $content = read_glob_content($fh);

Same as I<read_file_content>, only it accepts a file handler.

Returns the content and B<closes the file handler>.

=head1 EXPORT

Nothing by default. You can provide a list of subroutines to import.

=head1 AUTHOR

Alexis Sukrieh

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2010 Alexis Sukrieh.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

