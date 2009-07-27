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
$VERSION = '0_0.99';
@EXPORT = qw(
    before
    content_type
    dirname
    false
    get 
    layout
    mime_type
    params
    pass
    path
    post 
    r
    request
    send_file
    set
    splat
    status
    template
    true
    var
    vars
);

# Dancer's syntax 

sub before       { Dancer::Route->before_filter(@_) }
sub content_type { Dancer::Response::content_type(@_) }
sub dirname      { Dancer::FileUtils::dirname(@_) }
sub false        { 0 }
sub get          { Dancer::Route->add('get', @_) }
sub layout       { set(layout => shift) }
sub mime_type    { Dancer::Config::mime_types(@_) }
sub params       { Dancer::SharedData->params  }
sub pass         { Dancer::Response::pass() }
sub path         { Dancer::FileUtils::path(@_) }
sub post         { Dancer::Route->add('post', @_) }
sub r            { {regexp => $_[0]} }
sub request      { Dancer::SharedData->cgi }
sub send_file    { Dancer::Helpers::send_file(@_) }
sub set          { setting(@_) }
sub splat        { @{ Dancer::SharedData->params->{splat} } }
sub status       { Dancer::Response::status(@_) }
sub template     { Dancer::Helpers::template(@_) }
sub true         { 1 }
sub var          { Dancer::SharedData->var(@_) }
sub vars         { Dancer::SharedData->vars }

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
    my ($self, $cgi) = @_;
    
    Dancer::SharedData->cgi($cgi);

    return Dancer::Renderer->render_file
        || Dancer::Renderer->render_action
        || Dancer::Renderer->render_error;
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

=head1 DESCRIPTION

Dancer is a web application framework designed to be as effortless as possible
for the developer.

Dancer is here to provide the simpliest way for writing a web application.

It can be use to write light-weight web services or small standalone web
applications.

If you don't want to write a CGI by hand and find Catalyst too big for your
project, Dancer is what you need.

=head1 USAGE

As soon as Dancer is imported to a script, that script becomes a webapp.

All the script has to do is to declare a list of B<routes>.
    
A route handler is composed by an HTTP method, a path pattern and a code block.

The code block given to the route handler has to return a string which will be
used as the content to render to the client.

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

=head1 FILTERS

=head2 Before filters

Before filters are evaluated before each request within the context of the
request and can modify the request and response. It's possible to define variable 
that will be accessible in the action blocks with the keyword 'var'.

    before sub {
        var note => 'Hi there';
        request->path_info('/foo/oversee')
    };
    
    get '/foo/*' => sub {
        my ($match) = splat; # 'oversee';
        vars->{note}; # 'Hi there'
    };

The request keyword returns the current CGI object representing the incoming request.
See the documentation of the L<CGI> module for details.

=head1 USING TEMPLATES

=head1 VIEWS 

It's possible to render the action's content with a template, this is called a
view. The `appdir/views' directory is the place where views are located. 

You can change this location by changing the setting 'views', for instance if
your templates are located in the 'templates' directory, do the following:

    set views => path(dirname(__FILE__), 'templates');

A view should have a '.tt' extension and is rendered with the
L<Template> module. You have to import the `Template' module in your script if
you want to render views within your actions.

In order to render a view, just call the 'template' keyword at the end of the
action by giving the view name and the HASHREF of tokens to interpolate in the
view (note that all the route params are accessible in the view):

    use Dancer;
    use Template;

    get '/hello/:name' => sub {
        template 'hello' => {var => 42};
    };

And the appdir/views/hello.tt view can contain the following code:

   <html>
    <head></head>
    <body>
        <h1>Hello <% params.name %></h1>
    </body>
   </html>

=head2 LAYOUTS

A layout is a special view, located in the 'layouts' directory (inside the
views directory) which must have a token named `content'. That token marks the
place where to render the action view. This lets you define a global layout for
your actions. 

Here is an example of a layout: views/layouts/main.tt :

    <html>
        <head>...</head>
        <body>
        <div id="header">
        ...
        </div>

        <div id="content">
        <% content %>
        </div>

        </body>
    </html>

This layout can be used like the following:

    use Dancer;
    use Template; 

    layout 'main';

    get '/' => sub {
        template 'index';
    };

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
