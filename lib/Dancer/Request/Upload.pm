package Dancer::Request::Upload;

use File::Spec;
use Carp;

use strict;
use warnings;
use base 'Dancer::Object';
use Dancer::FileUtils qw(open_file);
use Dancer::Exception qw(:all);

Dancer::Request::Upload->attributes(
    qw(
      filename tempname headers size
      )
);

sub file_handle {
    my ($self) = @_;
    return $self->{_fh} if defined $self->{_fh};
    my $fh = open_file('<', $self->tempname) 
      or raise core_request => "Can't open `" . $self->tempname . "' for reading: $!";
    $self->{_fh} = $fh;
}

sub copy_to {
    my ($self, $target) = @_;
    require File::Copy;
    File::Copy::copy($self->{tempname}, $target);
}

sub link_to {
    my ($self, $target) = @_;
    CORE::link($self->{tempname}, $target);
}

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

sub basename {
    my ($self) = @_;
    require File::Basename;
    File::Basename::basename($self->filename);
}

sub type {
    my $self = shift;

    return $self->headers->{'Content-Type'};
}



# private

=pod

=head1 NAME 

Dancer::Request::Upload - class representing file uploads requests

=head1 DESCRIPTION

This class implements a representation of file uploads for Dancer.
These objects are accesible within route handlers via the request->uploads 
keyword. See L<Dancer::Request> for details.

=head1 METHODS

=over 4

=item filename

Returns the filename as sent by the client.

=item basename

Returns basename for "filename".

=item tempname

Returns the name of the temporary file the data has been saved to.

This will be in e.g. /tmp, and given a random name, with no file extension.

=item link_to

Creates a hard link to the temporary file. Returns true for success,
false for failure.

    $upload->link_to('/path/to/target');

=item file_handle

Returns a read-only file handle on the temporary file.

=item content

Returns a scalar containing the contents of the temporary file.

=item copy_to

Copies the temporary file using File::Copy. Returns true for success,
false for failure.

    $upload->copy_to('/path/to/target')

=item size

The size of the upload, in bytes.

=item headers

Returns a hash ref of the headers associated with this upload.

=item type

The Content-Type of this upload.

=back

=head1 AUTHORS

This module as been writen by Alexis Sukrieh, heavily based on
L<Plack::Request::Upload>. Kudos to Plack authors.

=head1 SEE ALSO

L<Dancer>

=cut

1;
