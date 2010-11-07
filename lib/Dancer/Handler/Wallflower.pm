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
