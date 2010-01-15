package Dancer;

use strict;
use warnings;
use Carp 'confess';
use vars qw($VERSION $AUTHORITY @EXPORT);

use Dancer::Config 'setting';
use Dancer::FileUtils;
use Dancer::GetOpt;
use Dancer::Error;
use Dancer::Exceptions;
use Dancer::Helpers;
use Dancer::Logger;
use Dancer::Renderer;
use Dancer::Response;
use Dancer::Route;
use Dancer::Session;
use Dancer::SharedData;
use Dancer::Handler;

use base 'Exporter';

$AUTHORITY = 'SUKRIA';
$VERSION = '1.120';
@EXPORT = qw(
    any
    before
    cookies
    content_type
    dance
    debug
    del
    dirname
    error
    false
    get 
    layout
    load
    logger
    mime_type
    options
    params
    pass
    path
    post 
    put
    r
    redirect
    request
    send_file
    send_error
    set
    set_cookie
    session
    splat
    status
    template
    true
    var
    vars
    warning
);

# Dancer's syntax 

sub any          { Dancer::Route->add_any(@_) }
sub before       { Dancer::Route->before_filter(@_) }
sub cookies      { Dancer::Cookies->cookies }
sub content_type { Dancer::Response::content_type(@_) }
sub debug        { Dancer::Logger->debug(@_) }
sub dirname      { Dancer::FileUtils::dirname(@_) }
sub error        { Dancer::Logger->error(@_) }
sub send_error   { Dancer::Helpers->error(@_) }
sub false        { 0 }
sub get          { Dancer::Route->add('head', @_); 
                   Dancer::Route->add('get', @_);}
sub layout       { set(layout => shift) }
sub logger       { set(logger => @_) }
sub load         { require $_ for @_ }
sub mime_type    { Dancer::Config::mime_types(@_) }
sub params       { Dancer::SharedData->params  }
# sub pass         { Dancer::Response::pass() }
sub pass         { pass_exception }
sub path         { Dancer::FileUtils::path(@_) }
sub post         { Dancer::Route->add('post', @_) }
sub del          { Dancer::Route->add('delete', @_) }
sub options      { Dancer::Route->add('options', @_) }
sub put          { Dancer::Route->add('put', @_) }
sub r            { {regexp => $_[0]} }
sub redirect     { Dancer::Helpers::redirect(@_) }
sub request      { Dancer::SharedData->request }
sub send_file    { Dancer::Helpers::send_file(@_) }
sub set          { setting(@_) }
sub set_cookie   { Dancer::Helpers::set_cookie(@_) }
sub session      { 
    if (@_ == 0) {
        return Dancer::Session->get;
    }
    else {
        return (@_ == 1) 
            ? Dancer::Session->read(@_) 
            : Dancer::Session->write(@_) 
    }
}
sub splat        { @{ Dancer::SharedData->params->{splat} } }
sub status       { Dancer::Response::status(@_) }
sub template     { Dancer::Helpers::template(@_) }
sub true         { 1 }
sub var          { Dancer::SharedData->var(@_) }
sub vars         { Dancer::SharedData->vars }
sub warning      { Dancer::Logger->warning(@_) }

# When importing the package, strict and warnings pragma are loaded, 
# and the appdir detection is performed.
sub import {
    my ($class, $symbol) = @_;
    my ($package, $script) = caller;
    strict->import;
    warnings->import;

    $class->export_to_level( 1, $class, @EXPORT );

    # if :syntax option exists, don't change settings
    if ( $symbol && $symbol eq ':syntax' ) {
        return;
    }

    setting appdir => dirname(File::Spec->rel2abs($script));
    setting public => path(setting('appdir'), 'public');
    setting views  => path(setting('appdir'), 'views');
    setting logger => 'file';
}

# Start/Run the application with the chosen apphandler
sub dance { 
    my ($class, $request) = @_;
    Dancer::Config->load;
    Dancer::Handler->get_handler()->dance($request);
}

1;
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

As soon as Dancer is imported to a script, that script becomes a webapp.  All
the script has to do is to declare a list of B<routes>.  A route handler is
composed by an HTTP method, a path pattern and a code block.

The code block given to the route handler has to return a string which will be
used as the content to render to the client.

Routes are defined for a given HTTP method. For each method
supported, a keyword is exported by the module. 

Here is an example of a route definition:

    get '/hello/:name' => sub {
        # do something important here
        
        return "Hello ".params->{name};
    };

The route is defined for the method 'get', so only GET requests will be honoured
by that route.

=head2 HTTP METHODS

All existing HTTP methods are defined in the RFC 2616
L<http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html>. 

Here are the ones you can use to define your route handlers.

=over 8

=item B<GET>        The GET method retrieves information (when defining a route
                    handler for the GET method, Dancer automatically defines a 
                    route handler for the HEAD method, in order to honour HEAD
                    requests for each of your GET route handlers).
                    To define a GET action, use the B<get> keyword.

=item B<POST>       The POST method is used to create a ressource on the
                    server.
                    To define a POST action, use the B<post> keyword.

=item B<PUT>        The PUT method is used to update an existing ressource.
                    To define a PUT action, use the B<put> keyword.

=item B<DELETE>     The DELETE method requests that the origin server delete
                    the resource identified by the Request-URI.
                    To define a DELETE action, use the B<del> keyword.

=back

You can also use the special keyword B<any> to define a route for multiple
methods at once. For instance, you may want to define a route for both GET and
POST methods, this is done like the following:

    any ['get', 'post'] => '/myaction' => sub {
        # code
    };

Or even, a route handler that would match any HTTP methods:

    any '/myaction' => sub {
        # code
    };


=head2 ROUTE HANDLERS

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

=head2 RUNNING THE WEBSERVER

Once the script is ready, you can run the webserver just by running the
script. The following options are supported:

=over 8

=item B<--port=XXXX>    set the port to listen to (default is 3000)

=item B<--daemon>       run the webserver in the background

=item B<--help>         display a detailed help message

=back

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

=head2 redirect

The redirect action is a helper and shortcut to a common HTTP response code (302).
You can either redirect to a complete different site or you can also do it
within the application:

    get '/twitter', sub {
	    redirect 'http://twitter.com/me';
    };

You can also force Dancer to return an specific 300-ish HTTP response code:

    get '/old/:resouce', sub {
        redirect '/new/'.params->{resource}, 301;
    };

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

=head1 ERROR HANDLING

=head2 DEFAULT ERROR PAGES

When an error is renderered (the action responded with a status code different
than 200), Dancer first looks in the public directory for an HTML file matching
the error code (eg: 500.html or 404.html).

If such a file exists, it's used to render the error, otherwise, a default
error page will be rendered on the fly.

=head2 EXECUTION ERRORS

When an error occurs during the route execution, Dancer will render an error
page with the HTTP status code 500.

It's possible either to display the content of the error message or to hide it
with a generic error page.

This is a choice left to the end-user and can be set with the
B<show_errors> setting.

Note that you can also choose to consider all warnings in your route handlers
as errors when the setting B<warnings> is set to 1.

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

=head1 CONFIGURATION AND ENVIRONMENTS

Configuring a Dancer application can be done in many ways. The easiest one (and
maybe the the dirtiest) is to put all your settings statements at the top of
your script, before calling the dance() method.

Other ways are possible, you can write all your setting calls in the file
`appdir/config.yml'. For this, you must have installed the YAML module, and of
course, write the conffile in YAML. 

That's better than the first option, but it's still not
perfect as you can't switch easily from an environment to another without
rewriting the config.yml file.

The better way is to have one config.yml file with default global settings,
like the following:

    # appdir/config.yml
    logger: 'file'
    layout: 'main'

And then write as many environment file as you like in appdir/environements.
That way, the good environment config file will be loaded according to the
running environment (if none specified, it will be 'development').

Note that you can change the running environment using the --environment
commandline switch.

Typically, you'll want to set the following values in a development config
file:

    # appdir/environments/development.yml
    log: 'debug'
    access_log: 1

And in a production one:

    # appdir/environments/production.yml
    log: 'warning'
    access_log: 0

=head2 load

You can use the load method to include additional routes into your application:

    get '/go/:value', sub {
        # foo
    };

    load 'more_routes.pl';

    # then, in the file more_routes.pl:
    get '/yes', sub {
        'orly?';
    };

B<load> is just a wrapper for B<require>, but you can also specify a list of
routes files:

    load 'login_routes.pl', 'session_routes.pl', 'misc_routes.pl';

=head1 importing just the syntax

If you want to use more complex files hierarchies, you can import just the syntax of Dancer.

    package App;

    use Dancer;            # App may contain generic routes
    use App::User::Routes; # user-related routes

Then in App/User/Routes.pm:

    use Dancer ':syntax';

    get '/user/view/:id' => sub {
        ...
    };

=head1 LOGGING

It's possible to log messages sent by the application. In the current version,
only one method is possible for logging messages but it may come in future
releases new methods.

In order to enable the logging system for your application, you first have to
start the logger engine in your config.yml

    log: 'file'

Then you can choose which kind of messages you want to actually log:

    log: 'debug'     # will log debug, warning and errors
    log: 'warning'   # will log warning and errors
    log: 'error'     # will log only errors

A directory appdir/logs will be created and will host one logfile per
environment. The log message contains the time it was written, the PID of the
current process, the message and the caller information (file and line).

=head1 USING TEMPLATES

=head1 VIEWS 

It's possible to render the action's content with a template, this is called a
view. The `appdir/views' directory is the place where views are located. 

You can change this location by changing the setting 'views', for instance if
your templates are located in the 'templates' directory, do the following:

    set views => path(dirname(__FILE__), 'templates');

By default, the internal template engine is used (L<Dancer::Template::Simple>)
but you may want to upgrade to Template::Toolkit. If you do so, you have to
enable this engine in your settings as explained in
L<Dancer::Template::TemplateToolkit>. If you do so, you'll also have to import
the L<Template> module in your application code. Note that Dancer configures
the Template::Toolkit engine to use <% %> brackets instead of its default
[% %] brackets.

All views must have a '.tt' extension. This may change in the future.

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

This module has been written by Alexis Sukrieh <sukria@cpan.org> and others,
see the AUTHORS file that comes with this distribution for details.

=head1 SOURCE CODE

The source code for this module is hosted on GitHub
L<http://github.com/sukria/Dancer>

=head1 DEPENDENCIES

Dancer depends on the following modules:

The following modules are mandatory (Dancer cannot run without them)

=over 8

=item L<HTTP::Server::Simple>

=item L<CGI>

=item L<Template>

=back

The following modules are optional 

=over 8

=item L<YAML> : needed for configuration file support

=item L<File::MimeInfo::Simple>

=back

=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.

=head1 SEE ALSO

The concept behind this module comes from the Sinatra ruby project, 
see L<http://www.sinatrarb.com> for details.

=cut
