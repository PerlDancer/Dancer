package Dancer::Renderer;

use strict;
use warnings;

use CGI qw/:standard/;
use Dancer::Route;
use Dancer::HTTP;
use Dancer::Request;
use Dancer::Response;
use Dancer::Config 'setting';
use Dancer::FileUtils qw(path dirname read_file_content);
use File::MimeInfo;
use Dancer::SharedData;

sub render_file {
    my $request = Dancer::SharedData->cgi;
    return get_file_response();
}

sub render_action {
    my $request = Dancer::SharedData->cgi;
    return get_action_response();
}

sub render_error {
    my ($class, $error_code) = @_;

    my $request = Dancer::Request->new;
    my $path    = $request->path;
    my $method  = $request->method;
    my $cgi     = $request->{_cgi};

    my $static_file = path(setting('public'), "$error_code.html");
    my $response = Dancer::Renderer->get_file_response_for_path(
        $static_file => $error_code);
    return $response if $response;

    return Dancer::Response->new(
        status => $error_code,
        headers => { 'Content-Type' => 'text/html' },
        content => Dancer::Renderer->html_page(
            "Error $error_code" =>
            "<h2>Unable to process your query</h2>".
            "The page you requested is not available"));
}

sub html_page {
    my ($class, $title, $content, $style) = @_;
    $style ||= 'style';

    my $cgi = CGI->new;
    return start_html(
        -title => $title, 
        -style => "/css/$style.css")
             . h1($title)
             . "<div id=\"content\">"
             . "<p>$content</p>"
             . "</div>"
             . '<div id="footer">'
             . 'Powered by <a href="http://dancer.sukria.net">Dancer</a>'
             . '</div>'
             . end_html();
}

sub get_action_response() {
    Dancer::Route->run_before_filters;

    my $request = Dancer::Request->new;
    my $path = $request->path;
    my $method = $request->method;
    
    my $handler = Dancer::Route->find($path, $method);
    Dancer::Route->call($handler) if $handler;
}

sub get_file_response() {
    my $request = Dancer::Request->new;
    my $path = $request->path;
    my $static_file = path(setting('public'), $path);
    return Dancer::Renderer->get_file_response_for_path($static_file);
}

sub get_file_response_for_path {
    my ($class, $static_file, $status) = @_;
    $status ||= 200;

    if (-f $static_file) {
        Dancer::Logger->debug("mime for $static_file is :
        ".get_mime_type($static_file));

        open my $fh, "<", $static_file;
        return Dancer::Response->new(
            status => $status,
            headers => { 'Content-Type' => get_mime_type($static_file) }, 
            content => $fh);
    }
    return undef;
}

# private

sub get_mime_type {
    my ($filename) = @_;
    my @tokens = reverse(split(/\./, $filename));
    my $ext = $tokens[0];
    
    my $mime = Dancer::Config::mime_types($ext);
    return (defined $mime) 
        ? $mime
        : mimetype($filename);
}

'Dancer::Renderer';
