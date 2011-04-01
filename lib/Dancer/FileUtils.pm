package Dancer::FileUtils;

use strict;
use warnings;

use File::Basename ();
use File::Spec;
use Carp;
use Cwd 'realpath';

use base 'Exporter';
use vars '@EXPORT_OK';

@EXPORT_OK = qw(path dirname read_file_content read_glob_content open_file set_file_mode);

# Undo UNC special-casing catfile-voodoo on cygwin
sub _trim_UNC {
    if ($^O eq 'cygwin') {
        return if ($#_ < 0);
        my ($slashes, $part, @parts) = (0, undef, @_);
        while(defined($part = shift(@parts))) { last if ($part); $slashes++ }
        $slashes += ($part =~ s/^[\/\\]+//);
        if ($slashes == 2) {
            return("/" . $part, @parts);
        } else {
            my $slashstr = '';
            $slashstr .= '/' for (1 .. $slashes);
            return($slashstr . $part, @parts);
        }
    }
    return(@_);
}
sub d_catfile { File::Spec->catfile(_trim_UNC(@_)) }
sub d_catdir { File::Spec->catdir(_trim_UNC(@_)) }
sub d_canonpath { File::Spec->canonpath(_trim_UNC(@_)) }
sub d_catpath { File::Spec->catpath(_trim_UNC(@_)) }
sub d_splitpath { File::Spec->splitpath(_trim_UNC(@_)) }

sub path { d_catfile(@_) }

sub path_no_verify {
    my @nodes = File::Spec->splitpath(d_catdir(@_)); # 0=vol,1=dirs,2=file
    my $path = '';

    # [0->?] path(must exist),[last] file(maybe exists)
    if($nodes[1]) {
        $path = realpath(File::Spec->catpath(@nodes[0 .. 1],'')) . '/';
    } else {
        $path = Cwd::cwd . '/';
    }
    $path .= $nodes[2];
    return $path;
}

sub dirname { File::Basename::dirname(@_) }

sub set_file_mode {
    my ($fh) = @_;
    require Dancer::Config;
    my $charset = Dancer::Config::setting('charset') || 'utf-8';

    if($charset) {
        binmode($fh, ":encoding($charset)");
    }
    return $fh;
}

sub open_file {
    my ($mode, $filename) = @_;
    open(my $fh, $mode, $filename)
      or croak "$! while opening '$filename' using mode '$mode'";
    return set_file_mode($fh);
}

sub read_file_content {
    my ($file) = @_;
    my $fh;

    if ($file) {
        $fh = open_file('<', $file);

        return wantarray ? read_glob_content($fh) : scalar read_glob_content($fh);
    }
    else {
        return;
    }
}

sub read_glob_content {
    my ($fh) = @_;

    # we don't want to do that as we'll encode the stuff later
    # binmode $fh;

    my @content = <$fh>;
    close $fh;

    return wantarray ? @content : join("", @content);
}

'Dancer::FileUtils';

__END__

=pod

=head1 NAME

Dancer::FileUtils - helper providing file utilities

=head1 SYNOPSIS

    use Dancer::FileUtils qw/path read_file_content/;

    my $content = read_file_content( path( 'folder', 'folder', 'file' ) );
    my @content = read_file_content( path( 'folder', 'folder', 'file' ) );

=head1 DESCRIPTION

Dancer::FileUtils includes a few file related utilities related that Dancer
uses internally. Developers may use it instead of writing their own
file reading subroutines or using additional modules.

=head1 SUBROUTINES/METHODS

=head2 open_file

    use Dancer::FileUtils 'open_file';
    my $fh = open_file('<', $file) or die $message;

Calls open and returns a filehandle. Takes in account the 'charset' setting to
open the file in the proper encoding.

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
    my @content = read_file_content($file);

Returns either the content of a file (whose filename is the input), I<undef>
if the file could not be opened.

In array context it returns each line (as defined by $/) as a seperate element
Scalar context returns the entire contents of the file.

=head2 read_glob_content

    use Dancer::FileUtils 'read_glob_content';

    open my $fh, '<', $file or die "$!\n";
    my $content = read_glob_content($fh);
    my @content = read_glob_content($fh);

Same as I<read_file_content>, only it accepts a file handle.

Returns the content and B<closes the file handle>.

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

