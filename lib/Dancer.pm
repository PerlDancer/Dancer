package Dancer;

use strict;
use warnings;
use vars qw($VERSION $AUTHORITY @EXPORT);

use Dancer::Config 'setting';
use Dancer::Route;
use Dancer::Renderer;
use Dancer::Response;
use Dancer::FileUtils;
use Dancer::SharedData;
use Dancer::Helpers;

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
    pass
    true
    false
    r
    dirname
    path
    params
    splat
    send_file
    mime_type
    template
);

# Dancer's syntax 
sub get          { Dancer::Route->add('get', @_) }
sub post         { Dancer::Route->add('post', @_) }
sub r            { {regexp => $_[0]} }
sub set          { setting(@_) }
sub mime_type    { Dancer::Config::mime_types(@_) }
sub dirname      { Dancer::FileUtils::dirname(@_) }
sub path         { Dancer::FileUtils::path(@_) }
sub true         { 1 }
sub false        { 0 }
sub params       { Dancer::SharedData->params  }
sub splat        { @{ Dancer::SharedData->params->{splat} } }
sub pass         { Dancer::Response::pass() }
sub status       { Dancer::Response::status(@_) }
sub content_type { Dancer::Response::content_type(@_) }
sub send_file    { Dancer::Helpers::send_file(@_) }
sub template     { Dancer::Helpers::template(@_) }

# The run method to call for starting the job
sub dance { 
    my $class = shift;
    my $ipaddr = setting 'server';
    my $port   = setting 'port';

    print ">> Listening on $ipaddr:$port\n";
    my $pid = $class->new($port)->run();
}

# HTTP server overload comes here
sub handle_request {
    my ($self, $request) = @_;
    
    return Dancer::Renderer->render_file($request) 
        || Dancer::Renderer->render_action($request)
        || Dancer::Renderer->render_error($request);
}

sub print_banner {
    print "== Entering the dance floor ...\n";
}

# When importing the package, strict and warnings pragma are loaded, 
# and the appdir detection is performed.
sub import {
    my ($package, $script) = caller;
    strict->import;
    warnings->import;

    setting appdir => dirname(File::Spec->rel2abs($script));
    setting public => path(setting('appdir'), 'public');
    setting views  => path(setting('appdir'), 'views');

    Dancer->export_to_level(1, @_);
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
        # do something important here
        
        return "Hello ".params->{name};
    };

The route is defined for the method 'get', so only GET requests will be honoured
by that route.

The route action is the code reference declared, it can access parameters through 
the `params' keyword, which returns an hashref.
This hashref is a merge of the route pattern matches and the request params.

Below are all the possible ways to define a route, note that it is not
possible to mix them up. Don't expect to have a working application if you mix
different kinds of route!

=head2 NAMED MATCHING

A route pattern can contain one or more tokens (a word prefixed with ':'). Each
token found in a route pattern is used as a named-pattern match. Any match will
be set in the params hashref.


    get '/hello/:name' => sub {
        "Hey ".params->{name}.", welcome here!";
    };

=head2 WILDCARDS MATCHING 

A route can contain a wildcard (represented by a '*'). Each wildcard match will
be returned in an arrayref, accessible via the `splat' keyword.

    get '/download/*.* => sub {
        my ($file, $ext) = splat;
        # do something with $file.$ext here
    };

=head2 REGULAR EXPRESSION MATCHING

A route can be defined with a Perl regular expression. The syntax is assumed to
be a classic Perl regexp except for the slashes that will be escaped before
running the match.

For instance, don't do '\/hello\/(.+)' but rather: '/hello/(.+)'

In order to tell Dancer to consider the route as a real regexp, the route must
be defined explicitly with the keyword 'r', like the following:
    
    get r( '/hello/([\w]+)' ) => sub {
        my ($name) = splat;
        return "Hello $name";
    };

=head1 ACTION SKIPPING

An action can choose not to serve the current request and ask Dancer to process
the request with the next matching route.

This is done with the B<pass> keyword, like in the following example
    
    get '/say/:word' => sub {
        pass if (params->{word} =~ /^\d+$/);
        "I say a word: ".params->{word};
    };

    get '/say/:number' => sub {
        "I say a number: ".params->{number};
    };

=head1 ACTION RESPONSES

The action's return value is always considered to be the content to render. So
take care to your return value.

In order to change the default behaviour of the rendering of an action, you can
use the following keywords.

=head2 status

By default, an action will produce an 'HTTP 200 OK' status code, meaning
everything is OK. It's possible to change that with the keyword B<status> :

    get '/download/:file' => {
        if (! -f params->{file}) {
            status 'not_found';
            return "File does not exist, unable to download";
        }
        # serving the file...
    };

In that example, Dancer will notice that the status has changed, and will
render the response accordingly.

The status keyword receives the name of the status to render, it can be either
an HTTP code or its alias, as defined in L<Dancer::HTTP>.

=head2 content_type

You can also change the content type rendered in the same maner, with the
keyword B<content_type>

    get '/cat/:txtfile' => {
        content_type 'text/plain';

        # here we can dump the contents of params->{txtfile}
    };

=head1 VIEWS 

It's possible to render your action views with a template. The appdir/views
directory is the place where views are located. 

You can change this location by changing the setting 'views', for instance if
your templates are located in the 'templates' directory, do the following:

    set views => path(dirname(__FILE__), 'templates');

The templates should avec a '.phtml' extension and are rendered with the
L<Template> module. You have to import the `Template' module in your script if
you want to render views within your actions.

In order to render a view, just call the 'template' keyword at the end of the
action by giving the view name and the HASHREF of tokens to interpolate in the
view (note that all the route params are accessible in the view):

    use Dancer;
    use Template;

    get '/hello/:name' => sub {
        template 'hello';
    };

And the appdir/views/hello.phtml view can contain the following code:

   <html>
    <head></head>
    <body>
        <h1>Hello <% params.name %></h1>
    </body>
   </html>

=head1 STATIC FILES

=head2 STATIC DIRECTORY

Static files are served from the ./public directory. You can specify a
different location by setting the 'public' option:

    set public => path(dirname(__FILE__), 'static');

Note that the public directory name is not included in the URL. A file
./public/css/style.css is made available as example.com/css/style.css. 

=head2 MIME-TYPES CONFIGURATION

By default, Dancer will automatically detect the mime-types to use for 
the static files accessed.

It's possible to choose specific mime-type per file extensions. For instance,
we can imagine you want to sever *.foo as a text/foo content, instead of
text/plain (which would be the content type detected by Dancer if *.foo are
text files).

        mime_type foo => 'text/foo';

This configures the 'text/foo' content type for any file matching '*.foo'.

=head2 STATIC FILE FROM A ROUTE HANDLER

It's possible for a route handler to pass the batton to a static file, like
the following.

    get '/download/*' => sub {
        my $params = shift;
        my ($file) = @{ $params->{splat} };

        send_file $file;
    };

Or even if you want your index page to be a plain old index.html file, just do:

    get '/' => sub {
        send_file '/index.html'
    };

=head1 SETTINGS

It's possible to change quite every parameter of the application via the
settings mechanism.

A setting is key/value pair assigned by the keyword B<set>:

    set setting_name => 'setting_value';

See L<Dancer::Config> for complete details about supported settings.

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
        "Hello ".params->{name}"
    };

    # run the webserver
    Dancer->dance;

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@cpan.org>

=head1 SOURCE CODE

The source code for this module is hosted on GitHub
L<http://github.com/sukria/Dancer>

=head1 DEPENDENCIES

Dancer depends on the following modules:

=over 4

=item L<HTTP::Server::Simple>

=item L<CGI>

=item L<File::MimeInfo>

=item L<File::Spec>

=item L<File::Basename>

=back

=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.

=head1 SEE ALSO

The concept behind this module comes from the Sinatra ruby project, 
see L<http://www.sinatrarb.com> for details.

=cut
