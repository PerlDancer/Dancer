package Dancer::Request::Upload;
# ABSTRACT: class representing a request upload


use File::Spec;
use Carp;

use strict;
use warnings;
use base 'Dancer::Object';
use Dancer::FileUtils qw(open_file);

Dancer::Request::Upload->attributes(
    qw(
      filename tempname headers size
      )
);


=attr tempname

Returns the name of the temporary file the data has been saved to.

This will be in e.g. /tmp, and given a random name, with no file extension.

=attr size

The size of the upload, in bytes.

=attr headers

Returns a hash ref of the headers associated with this upload.

=attr filename

Returns the filename as sent by the client.

=cut


=method file_handle

Returns a read-only file handle on the temporary file.

=cut
sub file_handle {
    my ($self) = @_;
    return $self->{_fh} if defined $self->{_fh};
    my $fh = open_file('<', $self->tempname) 
      or croak "Can't open `" . $self->tempname . "' for reading: $!";
    $self->{_fh} = $fh;
}

=method copy_to

Copies the temporary file using File::Copy. Returns true for success,
false for failure.

    $upload->copy_to('/path/to/target')

=cut
sub copy_to {
    my ($self, $target) = @_;
    require File::Copy;
    File::Copy::copy($self->{tempname}, $target);
}


=method link_to

Creates a hard link to the temporary file. Returns true for success,
false for failure.

    $upload->link_to('/path/to/target');

=cut
sub link_to {
    my ($self, $target) = @_;
    CORE::link($self->{tempname}, $target);
}

=method content

Returns a scalar containing the contents of the temporary file.

=cut
sub content {
    my ($self, $layer) = @_;
    return $self->{_content}
      if defined $self->{_content};

    $layer = ':raw' unless $layer;

    my $content = undef;
    my $handle  = $self->file_handle;

    binmode($handle, $layer);

    while ($handle->read(my $buffer, 8192)) {
        $content .= $buffer;
    }

    $self->{_content} = $content;
}


=method basename

Returns basename for "filename".

=cut
sub basename {
    my ($self) = @_;
    require File::Basename;
    File::Basename::basename($self->filename);
}

=method type

The Content-Type of this upload.

=cut
sub type {
    my $self = shift;

    return $self->headers->{'Content-Type'};
}

# privates

1;

__END__

=head1 DESCRIPTION

This class implements a representation of file uploads for Dancer.
These objects are accesible within route handlers via the
request->uploads keyword. See L<Dancer::Request> for details.

=cut

