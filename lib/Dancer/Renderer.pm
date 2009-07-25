package Dancer::Renderer;

use strict;
use warnings;

use Dancer::Route;
use Dancer::HTTP;
use Dancer::Config 'setting';
use Dancer::FileUtils qw(path dirname read_file_content);
use File::MimeInfo;
use Dancer::SharedData;

sub render_file($$) {
    my ($class, $request) = @_;
    
    my $response = get_file_response($request);
    if ($response) {
        print_response($response, $request);
    }
}

sub render_action($$) {
    my ($class, $request) = @_;

    my $response = get_action_response($request);
    if ($response) {
        print_response($response, $request);
    }
}

sub render_error($$) {
    my ($class, $request) = @_;
    
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

sub send_file { 
    my ($path) = @_;
    my $request = CGI->new;
    $request->path_info($path);
    $request->request_method('GET');
    my $resp = get_file_response($request);
    if ($resp) {
        Dancer::content_type($resp->{head}{content_type});
        return $resp->{body};
    }
    else {
        Dancer::status('error');
        "No such file: $path";
    }
}

sub get_action_response($) {
    my ($request) = @_;
    my $path = $request->path_info;
    my $method = $request->request_method;

    my $handler = Dancer::Route->find($path, $method);
    Dancer::Route->call($handler, $request) if ($handler);
}

sub get_file_response($) {
    my ($request) = @_;
    my $path = $request->path_info;
    my $static_file = path(setting('public'), $path);
    
    if (-f $static_file) {
        return {
            head => {content_type => mimetype($static_file)},
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
    print STDERR "== $method $path $st";
}

'Dancer::Renderer';
