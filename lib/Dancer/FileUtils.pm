package Dancer::FileUtils;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: helper providing file utilities
$Dancer::FileUtils::VERSION = '1.3202';
use strict;
use warnings;

use IO::File;

use File::Basename ();
use File::Spec;
use File::Temp qw(tempfile);

use Carp;
use Cwd 'realpath';

use Dancer::Exception qw(:all);

use base 'Exporter';
use vars '@EXPORT_OK';

@EXPORT_OK = qw(
    dirname open_file path read_file_content read_glob_content
    path_or_empty set_file_mode normalize_path
    atomic_write
);

# path should not verify paths
# just normalize
sub path {
    my @parts = @_;
    my $path  = File::Spec->catfile(@parts);

    return normalize_path($path);
}

sub path_or_empty {
    my @parts = @_;
    my $path  = path(@parts);

    # return empty if it doesn't exist
    return -e $path ? $path : '';
}

sub dirname { File::Basename::dirname(@_) }

sub set_file_mode {
    my $fh = shift;

    require Dancer::Config;
    my $charset = Dancer::Config::setting('charset') || 'utf-8';
    binmode $fh, ":encoding($charset)";

    return $fh;
}

sub open_file {
    my ( $mode, $filename ) = @_;

    open my $fh, $mode, $filename
      or raise core_fileutils => "$! while opening '$filename' using mode '$mode'";

    return set_file_mode($fh);
}

sub read_file_content {
    my $file = shift or return;
    my $fh   = open_file( '<', $file );

    return wantarray              ?
           read_glob_content($fh) :
           scalar read_glob_content($fh);
}

sub read_glob_content {
    my $fh = shift;

    # we don't want to do that as we'll encode the stuff later
    # binmode $fh;

    my @content = <$fh>;
    close $fh;

    return wantarray ? @content : join '', @content;
}

sub normalize_path {
    # this is a revised version of what is described in
    # http://www.linuxjournal.com/content/normalizing-path-names-bash
    # by Mitch Frazier
    my $path     = shift or return;
    my $seqregex = qr{
        [^/]*  # anything without a slash
        /\.\./ # that is accompanied by two dots as such
    }x;

    $path =~ s{/\./}{/}g;
    while ( $path =~ s{$seqregex}{} ) {}

    return $path;
}

# !! currently unused
# Undo UNC special-casing catfile-voodoo on cygwin
sub _trim_UNC {
    my @args = @_;

    # if we're using cygwin
    if ( $^O eq 'cygwin' ) {
        # no @args, no problem
        @args or return;

        my ( $slashes, $part, @parts) = ( 0, undef, @args );

        # start pulling part from @parts
        while ( defined ( $part = shift @parts ) ) {
            last if $part;
            $slashes++;
        }

        # count slashes in $part
        $slashes += ( $part =~ s/^[\/\\]+// );

        if ( $slashes == 2 ) {
            return ( '/' . $part, @parts );
        } else {
            my $slashstr = '';
            $slashstr .= '/' for ( 1 .. $slashes );

            return ( $slashstr . $part, @parts );
        }
    }

    return @args;
}

sub atomic_write {
    my ($path, $file, $data) = @_;
    my ($fh, $filename) = tempfile("tmpXXXXXXXXX", DIR => $path);
    set_file_mode($fh);
    print $fh $data;
    close $fh or die "Can't close '$file': $!\n";
    rename($filename, $file) or die "Can't move '$filename' to '$file'";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::FileUtils - helper providing file utilities

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

    use Dancer::FileUtils qw/dirname path/;

    # for 'path/to/file'
    my $dir  = dirname($path); # returns 'path/to'
    my $path = path($path);    # returns '/abs/path/to/file'


    use Dancer::FileUtils qw/path read_file_content/;

    my $content = read_file_content( path( 'folder', 'folder', 'file' ) );
    my @content = read_file_content( path( 'folder', 'folder', 'file' ) );

    use Dancer::FileUtils qw/read_glob_content set_file_mode/;

    open my $fh, '<', $file or die "$!\n";
    set_file_mode($fh);
    my @content = read_file_content($fh);
    my $content = read_file_content($fh);

=head1 DESCRIPTION

Dancer::FileUtils includes a few file related utilities related that Dancer
uses internally. Developers may use it instead of writing their own
file reading subroutines or using additional modules.

=head1 SUBROUTINES/METHODS

=head2 dirname

    use Dancer::FileUtils 'dirname';

    my $dir = dirname($path);

Exposes L<File::Basename>'s I<dirname>, to allow fetching a directory name from
a path. On most OS, returns all but last level of file path. See
L<File::Basename> for details.

=head2 open_file

    use Dancer::FileUtils 'open_file';
    my $fh = open_file('<', $file) or die $message;

Calls open and returns a filehandle. Takes in account the 'charset' setting
from Dancer's configuration to open the file in the proper encoding (or
defaults to utf-8 if setting not present).

=head2 path

    use Dancer::FileUtils 'path';

    my $path = path( 'folder', 'folder', 'filename');

Provides comfortable path resolving, internally using L<File::Spec>.

=head2 read_file_content

    use Dancer::FileUtils 'read_file_content';

    my @content = read_file_content($file);
    my $content = read_file_content($file);

Returns either the content of a file (whose filename is the input), I<undef>
if the file could not be opened.

In array context it returns each line (as defined by $/) as a separate element;
in scalar context returns the entire contents of the file.

=head2 read_glob_content

    use Dancer::FileUtils 'read_glob_content';

    open my $fh, '<', $file or die "$!\n";
    my @content = read_glob_content($fh);
    my $content = read_glob_content($fh);

Same as I<read_file_content>, only it accepts a file handle. Returns the
content and B<closes the file handle>.

=head2 set_file_mode

    use Dancer::FileUtils 'set_file_mode';

    set_file_mode($fh);

Applies charset setting from Dancer's configuration. Defaults to utf-8 if no
charset setting.

=head1 EXPORT

Nothing by default. You can provide a list of subroutines to import.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
