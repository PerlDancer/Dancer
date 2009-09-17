package Dancer::Renderer;

use strict;
use warnings;

use Dancer::Route;
use Dancer::HTTP;
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

# Here comes the gruick code for web server compat :(
sub get_path {
    my ($req) = @_;
    my $path = "";

    if (defined $ENV{'SCRIPT_NAME'}) {
        $path = $ENV{'SCRIPT_NAME'};
        $path .= $ENV{'PATH_INFO'} if $ENV{'PATH_INFO'};
    }
    else {
        $path = $req->path_info;
    }
    return $path;
}

sub get_request_method { $ENV{REQUEST_METHOD} || $_[0]->request_method }

sub render_error {
    my $request = Dancer::SharedData->cgi;
    my $path = get_path($request, \%ENV);
    my $method = get_request_method($request);

    return Dancer::Response->new(
        status => 404,
        headers => { 'Content-Type' => 'text/html' },
        content => $request->start_html('Not found').
        $request->h1('Not found').
        "<p>No route matched your request `$path'.</p>\n".
        "<p>".
        "appdir is <code>".setting('appdir')."</code><br>\n".
        "public is <code>".setting('public')."</code>".
        "</p>".
        $request->end_html);
}

sub get_action_response() {
    Dancer::Route->run_before_filters;

    my $request = Dancer::SharedData->cgi;
    my $path = get_path($request);
    my $method = get_request_method($request);
    
    my $handler = Dancer::Route->find($path, $method);
    Dancer::Route->call($handler) if $handler;
}

sub get_file_response() {
    my $request = Dancer::SharedData->cgi;
    my $path = get_path($request);
    my $static_file = path(setting('public'), $path);
    
    if (-f $static_file) {
        open my $fh, "<", $static_file;
        return Dancer::Response->new(
            status => 200,
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
