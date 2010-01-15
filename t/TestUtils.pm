package TestUtils;

use base 'Exporter';
use vars '@EXPORT';

use Dancer::Request;
@EXPORT = qw(fake_request http_request write_file get_response_for_request);

sub fake_request($$) {
	my ($method, $path) = @_;
    return Dancer::Request->new_for_request($method => $path);
}

sub http_request {
    my ($port, $method, $path) = @_;
    my $url = "http://localhost:${port}${path}";
    my $lwp = LWP::UserAgent->new;
    my $req = HTTP::Request->new($method => $url);
    return $lwp->request($req);
}

sub write_file {
    my ($file, $content) = @_;

    open CONF, '>', $file or die "cannot write file $file : $!";
    print CONF $content;
    close CONF;
}

sub get_response_for_request {
    my ($method, $path) = @_;
    my $request = fake_request($method => $path);
    Dancer::SharedData->request($request);
    Dancer::Renderer::get_action_response();
}

'TestUtils';
