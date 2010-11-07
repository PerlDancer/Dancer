package Dancer::Handler::Wallflower;

use strict;
use warnings;

use base 'Dancer::Handler';

use File::Path 'mkpath';

sub new { return bless {}, __PACKAGE__ }

sub dance {
    my ($self) = @_;
    my $setting = Dancer::Config::setting('handlers')->{wallflower} || {};
    my ($wwwdocs, $index) = @{$setting}{qw( destination index )};

    die "Destination not defined" if !defined $wwwdocs;
    die "Invalid destination '$wwwdocs'" if !-e $wwwdocs || !-d $wwwdocs;

    my $log;
    while (<>) {

        # ignore blank lines and comments
        next if /^\s*(#|$)/;
        chomp;

        # strip everything but the path
        my $url = URI->new(URI->new($_)->path);

        # default values
        my ($status, $file, $bytes) = (500, '-', '-');
        $log = "$status $url";

        # require an absolute path
        next if $url !~ /\//;

        # fake a minimal environment
        local $ENV{SERVER_NAME} = 'wallflower';
        local $ENV{SERVER_PORT} = '80';

        # create a new request object
        my $request = Dancer::Request->new_for_request(
            GET => $url    # method path params body headers
        );

        # obtain a response
        my $response = $self->handle_request($request);
        ($status, my $content) = @{$response}[0, 2];
        $log = "$status $url";

        # save successes to the appropriate file
        if ($status eq '200') {

            # absolute paths have the empty string as their first path_segment
            my (undef, @segments) = $url->path_segments;

            # assume directory
            push @segments, $index if $segments[-1] !~ /\./;

            # generate target file name
            my $file = File::Spec->catfile($wwwdocs, @segments);
            pop @segments;
            my $dir = File::Spec->catdir($wwwdocs, @segments);

            # ensure the subdirectory exists
            mkpath $dir if !-e $dir;
            open my $fh, '>', $file or die "Can't open $file for writing: $!";

            # copy content to the file
            if (ref $content eq 'ARRAY') {
                print $fh @$content;
            }
            elsif (ref $content eq 'GLOB') {
                print {$fh} <$content>;
            }
            elsif (eval { $content->can('getlines') }) {
                print {$fh} $content->getlines;
            }
            else {
                die "Don't know how to handle $content";
            }

            # finish
            close $fh;
            $bytes = -s $file;
            $log .= " => $file [$bytes]";
        }
    }
    continue {
        print "$log\n" if $log;
        $log = '';
    }
}

1;

__END__

=head1 NAME

Dancer::Handler::Wallflower - A static handler for Dancer

=head1 SYNOPSIS

    # recommended usage is through the wallflower script

=head1 DESCRIPTION

There are a number of websites that are in essence static, but that could
be written as a Dancer application, because it enables the author to do
more with less code.  Forms could be processed on the development server
(e.g. to update a local database), and the pages to be I<published>
would be a subset of all the URL that the application supports.

Turning such an application into a real static site (a set of pages
to upload to a static web server) is just a matter of generating all
possible URL for the static site and saving them to files.

This handler only handles GET requests, strips them from their query
string and saves the body response to a file whose name matches the
request pathinfo.

=head1 AUTHOR

Philippe Bruhat (BooK)

=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.

=cut

