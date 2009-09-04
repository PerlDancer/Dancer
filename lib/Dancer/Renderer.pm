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
    my $response = get_file_response();
    if ($response) {
        print_response($response, $request);
    }
}

sub render_action {
    my $request = Dancer::SharedData->cgi;
    my $response = get_action_response();
    if ($response) {
        print_response($response, $request);
    }
}

sub render_error {
    my $request = Dancer::SharedData->cgi;
    my $path = $request->path_info;
    my $method = $request->request_method;

    print Dancer::HTTP::status('not_found');
    print $request->header,
          $request->start_html('Not found'),
          $request->h1('Not found'),
          "<p>No route matched your request `$path'.</p>\n".
          "<p>".
          "appdir is <code>".setting('appdir')."</code><br>\n".
          "public is <code>".setting('public')."</code>".
          "</p>",
          $request->end_html;

    print STDERR "== $method $path 404 Not found\n" if setting('access_log');
}

sub get_action_response() {
    Dancer::Route->run_before_filters;

    my $request = Dancer::SharedData->cgi;
    my $path = $request->path_info;
    my $method = $request->request_method;
    
    my $handler = Dancer::Route->find($path, $method);
    Dancer::Route->call($handler) if $handler;
}

sub get_file_response() {
    my $request = Dancer::SharedData->cgi;
    my $path = $request->path_info;
    my $static_file = path(setting('public'), $path);
    
    
    if (-f $static_file) {
        return {
            head => {content_type => get_mime_type($static_file)},
            body => read_file_content($static_file),
        };
    }
    return undef;
}

sub print_response($$) {
    my ($resp, $request) = @_;
    my $path = $request->path_info;
    my $method = $request->request_method;

    my $ct = $resp->{head}{content_type} || setting('content_type');
    my $st = Dancer::HTTP::status($resp->{head}{status}) || Dancer::HTTP::status('ok');

    print $st;
    print $request->header($ct);
    print $resp->{body};
    
    if (setting('access_log')) {
        print STDERR "== $method $path $st";
    }
    return 1;
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
