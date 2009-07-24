package Dancer::Renderer;

use strict;
use warnings;

use Dancer::Route;
use Dancer::HTTP;
use Dancer::Config 'setting';
use Dancer::FileUtils qw(path dirname dump_file_content);
use File::MimeInfo;
use Dancer::SharedData;

sub render_file {
    my $cgi = Dancer::SharedData->cgi;
    my $path = $cgi->path_info;

    my $static_file = path(setting('public'), $path);
    
    if (-f $static_file) {
        print STDERR "== static: $path\n";
        print Dancer::HTTP::status('ok');
        print $cgi->header(mimetype($static_file));
        dump_file_content($static_file);
        return 1;
    }
    return 0;
}

sub render_action {
    Dancer::Route->run_before_filters;

    my $cgi = Dancer::SharedData->cgi;
    my $path = $cgi->path_info;
    my $method = $cgi->request_method;
    my $handler = Dancer::Route->find($path, $method);

    if ($handler) {
        # merging request and route params
        my $cgi_params = scalar($cgi->Vars);
        my $route_params = $handler->{params};
        my $params = (ref($route_params) ne 'HASH') 
                   ? $cgi_params 
                   : { %{$cgi_params}, %{$route_params} };

        Dancer::SharedData->params($params);
        my $resp = Dancer::Route->call($handler);

        Dancer::Route->run_after_filters;

        print_response($resp, $cgi, $method, $path);
    } 

}

sub render_error {
    my $cgi = Dancer::SharedData->cgi;
    my $path = $cgi->path_info;
    my $method = $cgi->request_method;

    print Dancer::HTTP::status('not_found');
    print $cgi->header,
          $cgi->start_html('Not found'),
          $cgi->h1('Not found'),
          "<p>No route matched your request `$path'.</p>\n".
          "<p>".
          "appdir is <code>".setting('appdir')."</code><br>\n".
          "public is <code>".setting('public')."</code>".
          "</p>",
          $cgi->end_html;

    print STDERR "== $method $path 404 Not found\n" if setting('access_log');
}

sub print_response {
    my ($resp, $cgi, $method, $path) = @_;

    my $ct = $resp->{head}{content_type} || setting('content_type');
    my $st = Dancer::HTTP::status($resp->{head}{status}) || Dancer::HTTP::status('ok');

    print $st;
    print $cgi->header($ct);
    print $resp->{body};
    print "\r\n";
        
    print STDERR "== $method $path $st";
}

'Dancer::Renderer';
