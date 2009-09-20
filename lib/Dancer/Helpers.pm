package Dancer::Helpers;

# helpers are function intended to be called from a route handler. They can
# alter the response of the route handler by changing the head or the body of
# the response.

use strict;
use warnings;

use CGI;
use Dancer::Response;
use Dancer::Config 'setting';
use Dancer::SharedData;

sub send_file { 
    my ($path) = @_;

    # Fake the CGI request with /path/to/file
    my $request = CGI->new;
    $request->path_info($path);
    $request->request_method('GET');
    Dancer::SharedData->cgi($request);

    my $resp = Dancer::Renderer::get_file_response();
    return $resp if $resp;

    my $error = Dancer::Error->new(
        code    => 404, 
        message => "No such file: `$path'");
    Dancer::Response::set($error->render);
}

sub template {
    my ($view, $tokens) = @_;
    $view .= ".tt" if $view !~ /\.tt$/;

    my $tt_config = {
        START_TAG => '<%',
        END_TAG => '%>',
        ANYCASE => 1,
    };

    $tokens ||= {};
    $tokens->{params} = Dancer::SharedData::params();
    $tokens->{request} = Dancer::SharedData->cgi;
    
    my $layout = setting('layout');
    my $content = '';
    my $tt = Template->new(INCLUDE_PATH => setting('views'), %{$tt_config});
    $tt->process($view, $tokens, \$content);
    return $content if not defined $layout;
 
    $layout .= '.tt' if $layout !~ /\.tt/;
    $tt = Template->new(
        INCLUDE_PATH => File::Spec->catdir(setting('views'), 'layouts'),
        %{$tt_config});
    my $full_content = '';
    $tt->process($layout, {%$tokens, content => $content}, \$full_content) or die "layout: $layout -> $!";
    return $full_content;
}

sub error {
    my ($class, $content, $status) = @_;
    $status ||= 500;

    my $error = Dancer::Error->new(code => $status, message => $content);
    Dancer::Response::set($error->render);
}

'Dancer::Helpers';
