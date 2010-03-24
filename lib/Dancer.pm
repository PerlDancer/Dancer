package Dancer;

use strict;
use warnings;
use Carp 'confess';
use vars qw($VERSION $AUTHORITY @EXPORT);

use Dancer::Config 'setting';
use Dancer::FileUtils;
use Dancer::GetOpt;
use Dancer::Error;
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
$VERSION   = '1.170';
@EXPORT    = qw(
  any
  before
  cookies
  config
  content_type
  dance
  debug
  del
  dirname
  error
  false
  get
  header
  headers
  layout
  load
  logger
  mime_type
  options
  params
  pass
  path
  post
  prefix
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
  upload
  uri_for
  var
  vars
  warning
);

# Dancer's syntax

sub any          { Dancer::Route->add_any(@_) }
sub before       { Dancer::Route->before_filter(@_) }
sub cookies      { Dancer::Cookies->cookies }
sub config       { Dancer::Config::settings() }
sub content_type { Dancer::Response::content_type(@_) }
sub debug        { Dancer::Logger->debug(@_) }
sub dirname      { Dancer::FileUtils::dirname(@_) }
sub error        { Dancer::Logger->error(@_) }
sub send_error   { Dancer::Helpers->error(@_) }
sub false        {0}

sub get {
    Dancer::Route->add('head', @_);
    Dancer::Route->add('get',  @_);
}
sub headers    { Dancer::Response::headers(@_); }
sub header     { goto &headers; }                      # goto ftw!
sub layout     { set(layout => shift) }
sub logger     { set(logger => @_) }
sub load       { require $_ for @_ }
sub mime_type  { Dancer::Config::mime_types(@_) }
sub params     { Dancer::SharedData->request->params(@_) }
sub pass       { Dancer::Response->pass }
sub path       { Dancer::FileUtils::path(@_) }
sub post       { Dancer::Route->add('post', @_) }
sub prefix     { Dancer::Route->prefix(@_) }
sub del        { Dancer::Route->add('delete', @_) }
sub options    { Dancer::Route->add('options', @_) }
sub put        { Dancer::Route->add('put', @_) }
sub r          { {regexp => $_[0]} }
sub redirect   { Dancer::Helpers::redirect(@_) }
sub request    { Dancer::SharedData->request }
sub send_file  { Dancer::Helpers::send_file(@_) }
sub set        { setting(@_) }
sub set_cookie { Dancer::Helpers::set_cookie(@_) }

sub session {
    if (@_ == 0) {
        return Dancer::Session->get;
    }
    else {
        return (@_ == 1)
          ? Dancer::Session->read(@_)
          : Dancer::Session->write(@_);
    }
}
sub splat    { @{Dancer::SharedData->request->params->{splat}} }
sub status   { Dancer::Response::status(@_) }
sub template { Dancer::Helpers::template(@_) }
sub true     {1}
sub upload   { Dancer::SharedData->request->upload(@_) }
sub uri_for  { Dancer::SharedData->request->uri_for(@_) }
sub var      { Dancer::SharedData->var(@_) }
sub vars     { Dancer::SharedData->vars }
sub warning  { Dancer::Logger->warning(@_) }

# When importing the package, strict and warnings pragma are loaded,
# and the appdir detection is performed.
sub import {
    my ($class,   $symbol) = @_;
    my ($package, $script) = caller;
    strict->import;
    warnings->import;

    $class->export_to_level(1, $class, @EXPORT);

    # if :syntax option exists, don't change settings
    if ($symbol && $symbol eq ':syntax') {
        return;
    }

    Dancer::GetOpt->process_args();
    setting appdir => dirname(File::Spec->rel2abs($script));
    setting public => path(setting('appdir'), 'public');
    setting views  => path(setting('appdir'), 'views');
    setting logger => 'file';
    setting confdir => $ENV{DANCER_CONFDIR} || setting('appdir');
    Dancer::Config->load;
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

Dancer - Lightweight yet powerful web application framework


=head1 SYNOPSIS

    #!/usr/bin/perl
    use Dancer;

    get '/hello/:name' => sub {
        return "Why, hello there " . params->{name};
    };

    dance;

The above is a basic but functional web app created with Dancer.  If you want to
see more examples and get up and running quickly, check out the
L<Dancer::Cookbook>.  For examples on deploying your Dancer applications, see
L<Dancer::Deployment>.


=head1 DESCRIPTION

Dancer is a web application framework designed to be as effortless as possible
for the developer, taking care of the boring bits as easily as possible, yet
staying out of your way and letting you get on with writing your code.

Dancer aims to provide the simplest way for writing web applications, and
offers the flexibility to scale between a very simple lightweight web service
consisting of a few lines of code in a single file, all the way up to a more
complex fully-fledged web application with session support, templates for views
and layouts, etc.

If you don't want to write CGI scripts by hand, and find Catalyst too big or
cumbersome for your project, Dancer is what you need.

Dancer has few pre-requisites, so your Dancer webapps will be easy to deploy.

Dancer apps can be used with a an embedded web server (great for easy testing),
and can run under PSGI/Plack for easy deployment in a variety of webserver
environments.

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

=item B<POST>       The POST method is used to create a resource on the
                    server.
                    To define a POST action, use the B<post> keyword.

=item B<PUT>        The PUT method is used to update an existing resource.
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

The route action is the code reference declared. It can access parameters through
the `params' keyword, which returns a hashref.
This hashref is a merge of the route pattern matches and the request params.

You can have more details about how params are built and how to access them in
the L<Dancer::Request> documentation.

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

    get '/download/*.*' => sub {
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

=head2 CONDITIONAL MATCHING

Routes may include some matching conditions (on the useragent and the hostname at the moment):

    get '/foo', {agent => 'Songbird (\d\.\d)[\d\/]*?'} => sub {
      'foo method for songbird'
    }

    get '/foo' => sub {
      'all browsers except songbird'
    }

=head2 PREFIX

A prefix can be defined for each route handler, like this:

    prefix '/home';

From here, any route handler is defined to /home/*

    get '/page1' => sub {}; # will match '/home/page1'

You can unset the prefix value

    prefix undef;
    get '/page1' => sub {}; will match /page1


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

You can also force Dancer to return a specific 300-ish HTTP response code:

    get '/old/:resource', sub {
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

=head2 file uploads

Dancer provides a common interface to handle file uploads. Any uploaded file is
accessible as a L<Dancer::Request::Upload> object. you can access all parsed
uploads via the upload keyword, like the following:

    post '/some/route' => sub {
        my $file = upload('file_input_foo');
        # file is a Dancer::Request::Upload object
    };

If you named multiple input of type "file" with the same name, the upload
keyword will return an array of Dancer::Request::Upload objects:

    post '/some/route' => sub {
        my ($file1, $file2) = upload('files_input');
        # $file1 and $file2 are Dancer::Request::Upload objects
    };

You can also access the raw hashref of parsed uploads via the current requesrt
object:

    post '/some/route' => sub {
        my $all_uploads = request->uploads;
        # $all_uploads->{'file_input_foo'} is a Dancer::Request::Upload object
        # $all_uploads->{'files_input'} is an array ref of Dancer::Request::Upload objects
    };

Note that you can also access the filename of the upload received via the params
keyword:

    post '/some/route' => sub {
        # params->{'files_input'} is the filename of the file uploaded
    };

See L<Dancer::Request::Upload> for details about the interface provided.

=head2 content_type

You can also change the content type rendered in the same maner, with the
keyword B<content_type>

    get '/cat/:txtfile' => {
        content_type 'text/plain';

        # here we can dump the contents of params->{txtfile}
    };

=head2 header(s)

It is possible to add custom headers to responses with the B<header> (or B<headers>)
keyword:

    get '/send/header', sub {
	    header 'X-My-Header' => 'shazam!';
    }

or...

    get '/send/headers', sub {
        headers 'X-Foo' => 'bar', X-Bar => 'foo';
    }

You can use both undistinctly, they do exactly what you expect them to do.

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
request and can modify the request and response. It's possible to define
variables which will be accessible in the action blocks with the keyword 'var'.

    before sub {
        var note => 'Hi there';
        request->path('/foo/oversee')
    };

    get '/foo/*' => sub {
        my ($match) = splat; # 'oversee';
        vars->{note}; # 'Hi there'
    };


For another example, this can be used along with session support to easily
give non-logged-in users a login page:

    before sub {
        if (!session('user') && request->path_info !~ m{^/login}) {
            # Pass the original path requested along to the handler:
            var requested_path => request->path_info;
            request->path_info('/login');
        }
    };


The request keyword returns the current Dancer::Request object representing the
incoming request. See the documentation of the L<Dancer::Request> module for details.

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

And then write as many environment files as you like in appdir/environments.
That way, the appropriate  environment config file will be loaded according to
the running environment (if none is specified, it will be 'development').

Note that you can change the running environment using the --environment
commandline switch.

Typically, you'll want to set the following values in a development config
file:

    # appdir/environments/development.yml
    log: 'debug'
    access_log: 1
    show_errors: 1

And in a production one:

    # appdir/environments/production.yml
    log: 'warning'
    access_log: 0
    show_errors: 0

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

=head2 Accessing configuration data

A Dancer application can access the information from its config file easily with
the config keyword:

    get '/appname' => sub {
        return "This is " . config->{appname};
    };


=head1 Importing just the syntax

If you want to use more complex files hierarchies, you can import just the
syntax of Dancer.

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
only one method is possible for logging messages but future releases may add
additional logging methods, for instance logging to syslog.

In order to enable the logging system for your application, you first have to
start the logger engine in your config.yml

    logger: 'file'

Then you can choose which kind of messages you want to actually log:

    log: 'debug'     # will log debug, warning and errors
    log: 'warning'   # will log warning and errors
    log: 'error'     # will log only errors

A directory appdir/logs will be created and will host one logfile per
environment. The log message contains the time it was written, the PID of the
current process, the message and the caller information (file and line).

To log messages, use the debug, warning and error methods, for instance:

    debug "This is a debug message";


=head1 USING TEMPLATES

=head1 VIEWS

It's possible to render the action's content with a template; this is called a
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
[% %] brackets, although you can change this in your config file.

All views must have a '.tt' extension. This may change in the future.

In order to render a view, just call the 'template' keyword at the end of the
action by giving the view name and the HASHREF of tokens to interpolate in the
view (note that the request, session and route params are automatically
accessible in the view, named request, session and params):

    use Dancer;
    use Template;

    get '/hello/:name' => sub {
        template 'hello' => { number => 42 };
    };

And the appdir/views/hello.tt view can contain the following code:

   <html>
    <head></head>
    <body>
        <h1>Hello <% params.name %></h1>
        <p>Your lucky number is <% number %></p>
        <p>You are using <% request.user_agent %></p>
        <% IF session.user %>
            <p>You're logged in as <% session.user %></p>
        <% END %>
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
we can imagine you want to serve *.foo as a text/foo content, instead of
text/plain (which would be the content type detected by Dancer if *.foo are
text files).

        mime_type foo => 'text/foo';

This configures the 'text/foo' content type for any file matching '*.foo'.

=head2 STATIC FILE FROM A ROUTE HANDLER

It's possible for a route handler to send a static file, as follows:

    get '/download/*' => sub {
        my $params = shift;
        my ($file) = @{ $params->{splat} };

        send_file $file;
    };

Or even if you want your index page to be a plain old index.html file, just do:

    get '/' => sub {
        send_file '/index.html'
    };

=head2 ROUTE CACHING

Dancer automatically supports default caching for routes. What this means is
that Dancer remembers for each path what route it took, so it doesn't have to
match it again.

This makes things B<much> faster, especially when dealing with many routes.
There are default limitations on the size of the cache and the number of
entries, so it doesn't get out of proportion.

Route caching can turned on using the I<route_cache> option in the
configuration:

    route_cache = 1

The default limitations are 10M in size or 600 entries in the cache, however you
can override these by settings the following settings:

    # limiting the size of the route cache
    route_cache_size_limit: 50M

    # limiting the number of paths that will be cached
    route_cache_path_limit: 300

=head1 SETTINGS

It's possible to change quite every parameter of the application via the
settings mechanism.

A setting is key/value pair assigned by the keyword B<set>:

    set setting_name => 'setting_value';

More usefully, settings can be defined in a YAML configuration file.
Environment-specific settings can also be defined in environment-specific files
(for instance, you don't want auto_reload in production, and might want extra
logging in development).  See the cookbook for examples.

See L<Dancer::Config> for complete details about supported settings.

=head1 SERIALIZERS

When writing a webservice, data serialization/deserialization is a common issue
to deal with. Dancer can automaticall handle that for you, via a serializer.

When setting up a serializer, a new behaviour is authorized for any route
handler you define: any non-scalar response will be rendered as a serialized
string, via the current serializer.

Here is an example of a route handler that will return a HashRef

    use Dancer;
    set serializer => 'JSON';

    get '/user/:id'/ => sub {
        { foo => 42,
          number => 100234,
          list => [qw(one two three)],
        }
    };

As soon as the content is not a scalar - and a serializer is set, which is not
the case by default - Dancer renders the response via the current
serializer.

Hence, with the JSON serializer set, the route handler above would result in a content like the following:

    {"number":100234,"foo":42,"list":["one","two","three"]}

The following serializers are available, be aware they dynamically depend on
Perl modules you may not have on your system.

=over 4

=item B<JSON>

requires L<JSON>

=item B<YAML>

requires L<YAML>

=item B<XML>

requires L<XML::Simple>

=item B<Mutable>

will try to find the appropriate serializer using the B<Content-Type> and B<Accept-type> header of the request.

=back

=head1 EXAMPLE

This is a possible webapp created with Dancer:

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


=head1 GETTING HELP / CONTRIBUTING

The Dancer development team can be found on #dancer on irc.perl.org:
L<irc://irc.perl.org/dancer>

There is also a Dancer users mailing list available - subscribe at:

L<http://lists.perldancer.org/cgi-bin/listinfo/dancer-users>


=head1 DEPENDENCIES

Dancer depends on the following modules:

The following modules are mandatory (Dancer cannot run without them)

=over 8

=item L<HTTP::Server::Simple::PSGI>

=item L<HTTP::Body>

=item L<MIME::Types>

=item L<URI>

=back

The following modules are optional

=over 8

=item L<Template> : In order to use TT for rendering views

=item L<YAML> : needed for configuration file support

=item L<File::MimeInfo::Simple>

=back

=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.

=head1 SEE ALSO

The concept behind this module comes from the Sinatra ruby project,
see L<http://www.sinatrarb.com/> for details.

=cut
