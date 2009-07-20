package Dancer;

use strict;
use warnings;
use vars qw($VERSION $AUTHORITY @EXPORT);

use Dancer::Config 'setting';
use Dancer::HTTP;
use Dancer::Route;
use Dancer::Response;
use HTTP::Server::Simple::CGI;
use base 'Exporter', 'HTTP::Server::Simple::CGI';

$AUTHORITY = 'SUKRIA';
$VERSION = '0.1';
@EXPORT = qw(
    set
    get 
    post 
    status
    content_type
);

# syntax sugar for our fellow users :)
sub set  { setting(@_) }
sub get  { Dancer::Route->add('get', @_) }
sub post { Dancer::Route->add('post', @_) }
sub status { Dancer::Response::status(@_) }
sub content_type { Dancer::Response::content_type(@_) }

# The run method to call for starting the job
sub dance { 
    my $class = shift;
    my ($ipaddr, $port) = (
        setting('server'), 
        setting('port'));
    print ">> Listening on $ipaddr:$port\n";
    my $pid = $class->new($port)->run();
}

# HTTP server overload comes here
sub handle_request {
    my ($self, $cgi) = @_;

    my $path = $cgi->path_info();
    my $method = $cgi->request_method;
    my $handler = Dancer::Route->find($path, $method);

    if ($handler) {
        my $params = _merge_params(scalar($cgi->Vars), $handler->{params});
        my $resp = Dancer::Route->call($handler, $params);
        print_response($resp, $cgi, $method, $path);

    } 
    else {
        print Dancer::HTTP::status('not_found');
        print $cgi->header,
              $cgi->start_html('Not found'),
              $cgi->h1('Not found'),
              $cgi->end_html;
        
        print STDERR "== $method $path 404 Not found\n" if setting('access_log');
    }
}

sub print_banner {
    print "== Entering the dance floor ...\n";
}

# private

sub _merge_params {
    my ($cgi_params, $route_params) = @_;
    return $cgi_params if ref($route_params) ne 'HASH';
    return { %{$cgi_params}, %{$route_params} };
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

'Dancer';
__END__

=pod 

=head1 NAME

Dancer 

=head1 WARNING

This is under heavy development

=head1 DESCRIPTION

Dancer is a framework for writing web applications with minimal effort. It was
inspired by Sinatra, from the Ruby's community.

Dancer is here to provide the simpliest way for writing a web application.

=head1 USAGE

As soon as Dancer is imported to a script, that script becomes a webapp.

All the script has to do is to declare a list of B<routes> which are basically:
    
=over 4

=item a B<pattern> for matching HTTP requests 

=item a B<block of code> that has to return a string supposed to be the content
to render.

=back

Routes are defined for a given HTTP method (get or post). For each method
supported, a keyword is exported by the module. 

Here is an example of a route definition:

    get '/hello/:name' => sub {
        my ($params) = @_;

        # do something important here
        
        return "Hello ".$params->{name};
    };

The route is defined for the method 'get', so only GET requests will be honoured
by that route.

The route action is the code reference declared, it receives the params as its
first argument. This hashref is a merge of the route pattern matches and the
request params.

Below are all the possible ways to define a route, note that it is not
possible to mix them up. Don't expect to have a working application if you mix
different kinds of route!

=head2 NAMED MATCHING

A route pattern can contain one or more tokens (a word prefixed with ':'). Each
token found in a route pattern is used as a named-pattern match. Any match will
be set in the params hashref given to the B<route action>.


    get '/hello/:name' => sub {
        my $params = shift;
        "Hey ".$params->{name}.", welcome here!";
    };

=head2 WILDCARDS MATCHING 

A route can contain a wildcard (represented by a '*'). Each wildcard match will
be returned in an arrayref, assigned to the "splat" key of the params hashref.

    get '/download/*.* => sub {
        my $params = shift;
        my ($file, $ext) = @{ $params->{splat} };
        # do something with $file.$ext here
    };

=head2 REGULAR EXPRESSION MATCHING

A route can be defined with a Perl regular expression. The syntax is assumed to
be a classic Perl regexp except for the slashes that will be escaped before
running the match.

For instance, don't do '\/hello\/(.+)' but rather: '/hello/(.+)'

In order to tell Dancer to consider the route as a real regexp, the route must
be defined explicitly with the keyword regexp, like the following:
    
    get {regexp => '/hello/([\w]+)'} => sub {
        my $params = shift;
        my ($name) = @{$params->{splat});
        return "Hello $name";
    };

=head1 EXAMPLE

This is a possible webapp created with Dancer :

    #!/usr/bin/perl
    
    # make this script a webapp
    use Dancer;

    # declare routes/actions
    get '/' => sub { 
        "Hello World";
    };

    get '/hello/:name' => sub {
        "Hello ".$params{name}"
    };

    # run the webserver
    Dancer->dance;

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@cpan.org>

=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.

=head1 SEE ALSO

The concept behind this module comes from the Sinatra ruby project, 
see L<http://www.sinatrarb.com> for details.

=cut
