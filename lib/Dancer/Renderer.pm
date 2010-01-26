package Dancer::Renderer;

use strict;
use warnings;

use CGI qw/:standard/;
use Dancer::Route;
use Dancer::HTTP;
use Dancer::Cookie;
use Dancer::Cookies;
use Dancer::Request;
use Dancer::Response;
use Dancer::Config 'setting';
use Dancer::FileUtils qw(path dirname read_file_content);
use Dancer::SharedData;

sub render_file {
    return get_file_response();
}

sub render_action {
    my $resp = get_action_response();
    return (defined $resp)
      ? response_with_headers($resp)
      : undef;
}

sub render_error {
    my ($class, $error_code) = @_;

    my $static_file = path(setting('public'), "$error_code.html");
    my $response = Dancer::Renderer->get_file_response_for_path(
        $static_file => $error_code);
    return $response if $response;

    return Dancer::Response->new(
        status  => $error_code,
        headers => ['Content-Type' => 'text/html'],
        content => Dancer::Renderer->html_page(
                "Error $error_code" => "<h2>Unable to process your query</h2>"
              . "The page you requested is not available"
        )
    );
}

# Takes a response object and add default headers
sub response_with_headers {
    my $response = shift;

    $response->{headers} ||= [];
    push @{$response->{headers}},
      ('X-Powered-By' => "Perl Dancer ${Dancer::VERSION}");

    # add cookies
    foreach my $c (keys %{Dancer::Cookies->cookies}) {
        my $cookie = Dancer::Cookies->cookies->{$c};
        if (Dancer::Cookies->has_changed($cookie)) {
            push @{$response->{headers}}, ('Set-Cookie' => $cookie->to_header);
        }
    }
    return $response;
}

sub html_page {
    my ($class, $title, $content, $style) = @_;
    $style ||= 'style';

    # TODO build the HTML with Dancer::Template::Simple
    return start_html(
        -title => $title,
        -style => "/css/$style.css"
      )
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

    my $request = Dancer::SharedData->request || Dancer::Request->new;
    my $path    = $request->path;
    my $method  = $request->method;

    my $handler = Dancer::Route->find($path, $method, $request);
    Dancer::Route->call($handler) if $handler;
}

sub get_file_response() {
    my $request     = Dancer::Request->new;
    my $path        = $request->path;
    my $static_file = path(setting('public'), $path);
    return Dancer::Renderer->get_file_response_for_path($static_file);
}

sub get_file_response_for_path {
    my ($class, $static_file, $status) = @_;
    $status ||= 200;

    if (-f $static_file) {
        open my $fh, "<", $static_file;
        return Dancer::Response->new(
            status  => $status,
            headers => ['Content-Type' => get_mime_type($static_file)],
            content => $fh
        );
    }
    return undef;
}

# private

sub get_mime_type {
    my ($filename) = @_;
    my @tokens = reverse(split(/\./, $filename));
    my $ext = $tokens[0];

    my $mime = Dancer::Config::mime_types($ext);
    return $mime if defined $mime;

    if (Dancer::ModuleLoader->load('File::MimeInfo::Simple')) {
        return File::MimeInfo::Simple::mimetype($filename);
    }
    else {
        die "unknown mime_type for '$filename', "
          . "register it with 'mime_type' or install "
          . "'File::MimeInfo::Simple'";
    }
}

1;
