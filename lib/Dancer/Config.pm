package Dancer::Config;

use strict;
use warnings;
use base 'Exporter';
use vars '@EXPORT_OK';

@EXPORT_OK = qw(setting mime_types);

# singleton for storing settings
my $SETTINGS = {};

# public accessor for get/set
sub setting {
    my ($setting, $value) = @_;
    (@_ == 2) 
        ? $SETTINGS->{$setting} = $value
        : $SETTINGS->{$setting} ;
}

sub mime_types {
    my ($ext, $content_type) = @_;
    $SETTINGS->{mime_types} ||= {};
    return $SETTINGS->{mime_types} if @_ == 0;

    return (@_ == 2) 
        ? $SETTINGS->{mime_types}{$ext} = $content_type
        : $SETTINGS->{mime_types}{$ext};
}


# load default settings

setting( server       => '127.0.0.1');
setting( port         => '1915'); # sinatra's birth year ;)
setting( content_type => 'text/html');
setting( charset      => 'UTF-8');
setting( access_log   => 1);

'Dancer::Config';
__END__
=pod

=head1 NAME

Dancer::Config

=head1 DESCRIPTION

Setting registry for Dancer

=head1 SETTINGS

You can change a setting with the keyword B<set>, like the following:

    use Dancer;

    # changing default settings
    set port => 8080;
    set content_type => 'text/plain';
    set access_log => 0;

Here is the list of all supported settings.

=head2 server (UNSUPPORTED)

The IP address or servername to bind to.
This setting is not yet implemented.

=head2 port 

The port Dancer will listen to.

Default value is 1915.

=head2 content_type 

The default content type of outgoing content.
Default value is 'text/html'.

=head2 charset

The default charset of outgoing content.
Default value is 'UTF-8'.

=head2 access_log

If set to 1 (default), Dancer will print on STDEER one line per hit received.

=head2 public 

This is the path of the public directory, where static files are stored. Any
existing file in that directory will be served as a static file, before
mathcing any route.

By default, it points to APPDIR/public where APPDIR is the directory that 
contains your Dancer script.

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@cpan.org>

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=head1 SEE ALSO

L<Dancer>

=cut
