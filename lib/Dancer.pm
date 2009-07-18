package Dancer;

use strict;
use warnings;
use vars qw($VERSION $AUTHORITY @EXPORT);

use Dancer::Registry;
use HTTP::Server::Simple::CGI;
use base 'Exporter', 'HTTP::Server::Simple::CGI';

$AUTHORITY = 'SUKRIA';
$VERSION = '0.1';
@EXPORT = qw(
    get 
    post 
);

sub handle_request {
    my ($self, $cgi) = @_;

    my $path = $cgi->path_info();
    my $handler = Dancer::Registry->find_route($path, $cgi->request_method);

    if ($handler) {
        print $cgi->header('text/plain');
        my $params = _merge_params(scalar($cgi->Vars), $handler->{params});
        print Dancer::Registry->call_route($handler, $params), "\n";
    } 
    else {
        print "HTTP/1.0 404 Not found\r\n";
        print $cgi->header,
              $cgi->start_html('Not found'),
              $cgi->h1('Not found'),
              $cgi->end_html;
    }
}

sub print_banner {
    print "== Entering the dance floor ...\n";
}

sub dance { 
    my $class = shift;
    my ($ipaddr, $port) = ('0.0.0.0', '8080');
    print ">> Listening on $ipaddr:$port\n";
    my $pid = $class->new($port)->run();
}

sub get  { Dancer::Registry->add_route('get', $_[0], $_[1])}
sub post { Dancer::Registry->add_route('post', $_[0], $_[1])}

# private

sub _merge_params {
    my ($cgi_params, $route_params) = @_;
    return $cgi_params if ref($route_params) ne 'HASH';
    return { %{$cgi_params}, %{$route_params} };
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

=head2 NAMED MATCHING

A route pattern can contain one or more tokens (a word prefixed with ':'). Each
token found in a route pattern is used as a named-pattern match. Any match will
be set in the params hashref given to the B<route action>.

The route action is the code reference declared, it receives the params as its
first argument. This hashref is a merge of the route pattern matches and de
request params.

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
