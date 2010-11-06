package Dancer::Handler::Wallflower;

use strict;
use warnings;

use base 'Dancer::Handler';

use File::Path;

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

        # strip query string and fragment
        my $url = URI->new(URI->new($_)->path);

        # default values
        my ($status, $file, $bytes) = (500, '-', '-');
        $log = "$status $url";

        # skip bad URL
        next if !/^\//;

        # fake an environment
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
        }
    }
    continue {
        print "$log\n" if $log;
        $log = '';
    }
}

1;

__END__
