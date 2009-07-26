package Dancer::Helpers;

# helpers are function intended to be called from a route handler. They can
# alter the response of the route handler by changing the head or the body of
# the response.

use strict;
use warnings;

use CGI;
use Dancer::Response;
use Dancer::Config 'setting';

sub send_file { 
    my ($path) = @_;

    my $request = CGI->new;
    $request->path_info($path);
    $request->request_method('GET');

    my $resp = Dancer::Renderer::get_file_response($request);
    if ($resp) {
        Dancer::Response::set($resp->{head});
        return $resp->{body};
    }
    else {
        Dancer::Response::status('error');
        "No such file: $path";
    }
}

sub template {
    my ($view, $tokens) = @_;
    $view .= ".phtml" if $view !~ /\.phtml$/;

    $tokens ||= {};
    $tokens->{params} = Dancer::SharedData::params();
    
    my $content = '';
    my $tt = Template->new(
        INCLUDE_PATH => setting('views'),
        START_TAG => '<%',
        END_TAG => '%>');
    $tt->process($view, $tokens, \$content);
    return $content;
}

'Dancer::Helpers';
