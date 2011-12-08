package LinkBlocker;
use Dancer ':syntax';
use Dancer::Plugin;

register block_links_from => sub {
    my ($host) = @_;
    hook before => sub {
        if (request->referer && request->referer =~ /http:\/\/$host/) {
            status 403;
        }
    };
};

add_hook(
    'after',
    sub {
        my $response = shift;
        if ( request->path eq '/test' ) {
            $response->{content} = 'no content';
            $response->{status}  = 202;
        }
    }
);

register_plugin;

1;
