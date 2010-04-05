package t::lib::LinkBlocker;
use Dancer ':syntax';
use Dancer::Plugin;

register block_links_from => sub {
    my ($host) = @_;
    before sub { 
        if (request->referer && request->referer =~ /http:\/\/$host/) {
            status 403;
        }
    };
};

register_plugin;
1;
