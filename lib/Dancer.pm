package Dancer;

use strict;
use warnings;
use Carp;
use Cwd 'abs_path', 'realpath';
use vars qw($VERSION $AUTHORITY @EXPORT);

use Dancer::Config;
use Dancer::FileUtils;
use Dancer::GetOpt;
use Dancer::Error;
use Dancer::Helpers;
use Dancer::Logger;
use Dancer::Plugin;
use Dancer::Renderer;
use Dancer::Response;
use Dancer::Route;
use Dancer::Serializer::JSON;
use Dancer::Serializer::YAML;
use Dancer::Serializer::XML;
use Dancer::Serializer::Dumper;
use Dancer::Session;
use Dancer::SharedData;
use Dancer::Handler;
use Dancer::ModuleLoader;

use File::Spec;
use File::Basename 'basename';

use base 'Exporter';

$AUTHORITY = 'SUKRIA';
$VERSION   = '1.1999_02';
@EXPORT    = qw(
  after
  any
  before
  before_template
  cookies
  config
  content_type
  dance
  debug
  del
  dirname
  error
  false
  from_dumper
  from_json
  from_yaml
  from_xml
  get
  halt
  header
  headers
  layout
  load
  load_app
  load_plugin
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
  setting
  set_cookie
  session
  splat
  status
  start
  template
  to_dumper
  to_json
  to_yaml
  to_xml
  true
  upload
  captures
  uri_for
  var
  vars
  warning
);

# Dancer's syntax

sub after           { Dancer::Route::Registry->hook('after',           @_) }
sub any             { Dancer::App->current->registry->any_add(@_) }
sub before          { Dancer::Route::Registry->hook('before',          @_) }
sub before_template { Dancer::Route::Registry->hook('before_template', @_) }
sub captures        { Dancer::SharedData->request->params->{captures} }
sub cookies         { Dancer::Cookies->cookies }
sub config          { Dancer::Config::settings() }
sub content_type    { Dancer::Response::content_type(@_) }
sub dance           { Dancer::start(@_) }
sub debug           { goto &Dancer::Logger::debug }
sub dirname         { Dancer::FileUtils::dirname(@_) }
sub error           { goto &Dancer::Logger::error }
sub send_error      { Dancer::Helpers->error(@_) }
sub false           {0}
sub from_dumper     { Dancer::Serializer::Dumper::from_dumper(@_) }
sub from_json       { Dancer::Serializer::JSON::from_json(@_) }
sub from_yaml       { Dancer::Serializer::YAML::from_yaml(@_) }
sub from_xml        { Dancer::Serializer::XML::from_xml(@_) }

sub get {
    Dancer::App->current->registry->universal_add('head', @_);
    Dancer::App->current->registry->universal_add('get',  @_);
}
sub halt      { Dancer::Response->halt(@_) }
sub headers   { Dancer::Response::headers(@_); }
sub header    { goto &headers; }                            # goto ftw!
sub layout    { set(layout => shift) }
sub load      { require $_ for @_ }
sub logger    { set(logger => @_) }
sub mime_type { Dancer::Config::mime_types(@_) }
sub params    { Dancer::SharedData->request->params(@_) }
sub pass      { Dancer::Response->pass }
sub path      { realpath(Dancer::FileUtils::path(@_)) }
sub post   { Dancer::App->current->registry->universal_add('post', @_) }
sub prefix { Dancer::App->current->set_prefix(@_) }
sub del     { Dancer::App->current->registry->universal_add('delete',  @_) }
sub options { Dancer::App->current->registry->universal_add('options', @_) }
sub put     { Dancer::App->current->registry->universal_add('put',     @_) }
sub r { carp "'r' is DEPRECATED use qr{} instead"; return {regexp => $_[0]} }
sub redirect  { Dancer::Helpers::redirect(@_) }
sub request   { Dancer::SharedData->request }
sub send_file { Dancer::Helpers::send_file(@_) }
sub set       { goto &setting }

sub setting {
    if (Dancer::App->applications) {
        return Dancer::App->current->setting(@_);
    }
    else {
        return Dancer::Config::setting(@_);
    }
}

sub set_cookie { Dancer::Helpers::set_cookie(@_) }

sub session {
    croak "Must specify session engine in settings prior to using 'session' keyword" unless setting('session');
    if (@_ == 0) {
        return Dancer::Session->get;
    }
    else {
        return (@_ == 1)
          ? Dancer::Session->read(@_)
          : Dancer::Session->write(@_);
    }
}
sub splat     { @{Dancer::SharedData->request->params->{splat}} }
sub status    { Dancer::Response::status(@_) }
sub template  { Dancer::Helpers::template(@_) }
sub true      {1}
sub to_dumper { Dancer::Serializer::Dumper::to_dumper(@_) }
sub to_json   { Dancer::Serializer::JSON::to_json(@_) }
sub to_yaml   { Dancer::Serializer::YAML::to_yaml(@_) }
sub to_xml    { Dancer::Serializer::XML::to_xml(@_) }
sub upload    { Dancer::SharedData->request->upload(@_) }
sub uri_for   { Dancer::SharedData->request->uri_for(@_) }
sub var       { Dancer::SharedData->var(@_) }
sub vars      { Dancer::SharedData->vars }
sub warning   { goto &Dancer::Logger::warning }

# FIXME handle previous usage of load_app with multiple app names
sub load_app {
    my ($app_name, %options) = @_;
    Dancer::Logger::core("loading application $app_name");

    # set the application
    my $app = Dancer::App->set_running_app($app_name);

    # Application options
    $app->prefix($options{prefix})     if $options{prefix};
    $app->settings($options{settings}) if $options{settings};


    # load the application
    my ($package, $script) = caller;
    _init($script);
    my ($res, $error) = Dancer::ModuleLoader->load($app_name);
    $res or croak "unable to load application $app_name : $error";

    # restore the main application
    Dancer::App->set_running_app('main');
}

sub load_plugin {
    goto &Dancer::Plugin::load_plugin;
}

# When importing the package, strict and warnings pragma are loaded,
# and the appdir detection is performed.
sub import {
    my ($class,   $symbol) = @_;
    my ($package, $script) = caller;

    strict->import;
    utf8->import;
    $class->export_to_level(1, $class, @EXPORT);

    # if :syntax option exists, don't change settings
    if ($symbol && $symbol eq ':syntax') {
        return;
    }

    Dancer::GetOpt->process_args();

    _init($script);
    Dancer::Config->load;
}

# Start/Run the application with the chosen apphandler
sub start {
    my ($class, $request) = @_;
    Dancer::Config->load;

    # Backward compatibility for app.psgi that has sub { Dancer->dance($req) }
    if ($request) {
        return Dancer::Handler->handle_request($request);
    }

    my $handler = Dancer::Handler->get_handler;
    Dancer::Logger::core("loading handler '".ref($handler)."'");
    return $handler->dance;
}


sub _init {
    my $script      = shift;
    my $script_path = File::Spec->rel2abs(path(dirname($script)));

    my $LAYOUT_PRE_DANCER_1_2 = 1;
    $LAYOUT_PRE_DANCER_1_2 = 0
      if ( basename($script) eq 'app.pl'
        || basename($script) eq 'dispatch.cgi'
        || basename($script) eq 'dispatch.fcgi');

    setting appdir => $ENV{DANCER_APPDIR}
      || (
          $LAYOUT_PRE_DANCER_1_2
        ? $script_path
        : File::Spec->rel2abs(path($script_path, '..'))
      );

    # once the dancer_appdir have been defined, we export to env
    $ENV{DANCER_APPDIR} = setting('appdir');

    Dancer::Logger::core(
        "initializing appdir to: `" . setting('appdir') . "'");

    setting confdir => $ENV{DANCER_CONFDIR}
      || setting('appdir');

    setting public => $ENV{DANCER_PUBLIC}
      || path(setting('appdir'), 'public');

    setting views => $ENV{DANCER_VIEWS}
      || path(setting('appdir'), 'views');

    setting logger => 'file';

    my ($res, $error) = Dancer::ModuleLoader->use_lib(path(setting('appdir'), 'lib'));
    $res or croak "unable to set libdir : $error";
}

1;
__END__

=pod

=head1 NAME

Dancer - lightweight yet powerful web application framework

=head1 SYNOPSIS

    #!/usr/bin/perl
    use Dancer;

    get '/hello/:name' => sub {
        return "Why, hello there " . params->{name};
    };

    dance;

The above is a basic but functional web app created with Dancer.  If you want
to see more examples and get up and running quickly, check out the
L<Dancer::Introduction> and the L<Dancer::Cookbook>.  For examples on
deploying your Dancer applications, see L<Dancer::Deployment>.

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

=head1 DISCLAIMER

This documentation describes all the exported symbols of Dancer. If you want
a quick start guide to discover the framework, you should look at
L<Dancer::Introduction>.

If you want to have specific examples of code for real-life problems, see the
L<Dancer::Cookbook>.

If you want to see configuration examples of different deployment solutions
involving Dancer and Plack, see L<Dancer::Deployment>.

=head1 METHODS

=head2 after

Add a hook at the B<after> position:

    after sub {
        my $response = shift;
        # do something with request
    };

The anonymous function which is given to C<after> will be executed after
having executed a route.

You can define multiple after filters, using the C<after> helper as
many times as you wish; each filter will be executed, in the order you added
them.

=head2 any

Defines a route for multiple HTTP methods at once:

    any ['get', 'post'] => '/myaction' => sub {
        # code
    };

Or even, a route handler that would match any HTTP methods:

    any '/myaction' => sub {
        # code
    };

=head2 before

Defines a before filter:

    before sub {
        # do something with request, vars or params
    };

The anonymous function which is given to C<before> will be executed before
looking for a route handler to handle the request.

You can define multiple before filters, using the C<before> helper as
many times as you wish; each filter will be executed in the order you added
them.

=head2 before_template

Defines a before_template filter:

    before_template sub {
        # do something with request, vars or params
    };

The anonymous function which is given to C<before_template> will be executed
before sending data and tokens to the template.

This filter works as the C<before> and C<after> filter.

=head2 cookies

Accesses cookies values, which returns a hashref of L<Dancer::Cookie> objects:

    get '/some_action' => sub {
        my $cookie = cookies->{name};
        return $cookie->value;
    };

=head2 config

Accesses the configuration of the application:

    get '/appname' => sub {
        return "This is " . config->{appname};
    };

=head2 content_type

Sets the B<content-type> rendered, for the current route handler:

    get '/cat/:txtfile' => sub {
        content_type 'text/plain';

        # here we can dump the contents of params->{txtfile}
    };

Note that if you want to change the default content-type for every route, you
have to change the setting C<content_type> instead.

=head2 dance

Alias for the C<start> keyword.

=head2 debug

Logs a message of debug level:

    debug "This is a debug message";

=head2 dirname

Returns the dirname of the path given:

    my $dir = dirname($some_path);

=head2 error

Logs a message of error level:

    error "This is an error message";

=head2 false

Constant that returns a false value (0).

=head2 from_dumper ($structure)

Deserializes a Data::Dumper structure.

=head2 from_json ($structure, %options)

Deserializes a JSON structure. Can receive optional arguments. Thoses arguments are valid L<JSON> arguments to change the behavior of the default C<JSON::from_json> function.

=head2 from_yaml ($structure)

Deserializes a YAML structure.

=head2 from_xml ($structure, %options)

Deserializes a XML structure. Can receive optional arguments. Thoses arguments are valid L<XML::Simple> arguments to change the behavior of the default C<XML::Simple::XMLin> function.

=head2 get

Defines a route for HTTP B<GET> requests to the given path:

    get '/' => sub {
        return "Hello world";
    }

=head2 halt

Sets a response object with the content given.

When used as a return value from a filter, this breaks the execution flow and
renders the response immediatly:

    before sub {
        if ($some_condition) {
            return halt("Unauthorized");
        }
    };

    get '/' => sub {
        "hello there";
    };

=head2 headers

Adds custom headers to responses:

    get '/send/headers', sub {
        headers 'X-Foo' => 'bar', X-Bar => 'foo';
    }

=head2 header

Adds a custom header to response:

    get '/send/header', sub {
        header 'X-My-Header' => 'shazam!';
    }

=head2 layout

Allows you to set the default layout to use when rendering a view.  Syntactic
sugar around the C<layout> setting:

    layout 'user';

=head2 logger

Allows you to set the logger engine to use.  Syntactic sugar around the
C<logger> setting:

    logger 'console';

=head2 load

Loads one or more perl scripts in the current application's namespace. Syntactic
sugar around Perl's C<require>:

    load 'UserActions.pl', 'AdminActions.pl';

=head2 load_app

Loads a Dancer package. This method takes care to set the libdir to the curent
C<./lib> directory:

    # if we have lib/Webapp.pm, we can load it like:
    load_app 'Webapp';

Note that a package loaded using load_app B<must> import Dancer with the
C<:syntax> option, in order not to change the application directory
(which has been previously set for the caller script).

=head2 load_plugin

Loads a plugin in the current namespace. As with load_app, the method takes
care to set the libdir to the current C<./lib> directory:

    package MyWebApp;
    use Dancer;

    load_plugin 'Dancer::Plugin::Database';

=head2 mime_type

Returns all the user-defined mime-types when called without parameters.
Behaves as a setter/getter when given parameters

    # get the global hash of user-defined mime-types:
    my $mimes = mime_types;

    # set a mime-type
    mime_types foo => 'text/foo';

    # get a mime-type
    my $m = mime_types 'foo';

=head2 params

I<This method should be called from a route handler>.
Alias for the L<Dancer::Request> params accessor.

=head2 pass

I<This method should be called from a route handler>.
Tells Dancer to pass the processing of the request to the next
matching route.

You should always C<return> after calling C<pass>:

    get '/some/route' => sub {
        if (...) {
            # we want to let the next matching route handler process this one
            return pass();
        }
    };

=head2 path

Concatenates multiple path together, without worrying about the underlying
operating system:

    my $path = path(dirname($0), 'lib', 'File.pm');

=head2 post

Defines a route for HTTP B<POST> requests to the given URL:

    POST '/' => sub {
        return "Hello world";
    }

=head2 prefix

Defines a prefix for each route handler, like this:

    prefix '/home';

From here, any route handler is defined to /home/*:

    get '/page1' => sub {}; # will match '/home/page1'

You can unset the prefix value:

    prefix undef;
    get '/page1' => sub {}; will match /page1

=head2 del

Defines a route for HTTP B<DELETE> requests to the given URL:

    del '/resource' => sub { ... };

=head2 options

Defines a route for HTTP B<OPTIONS> requests to the given URL:

    options '/resource' => sub { ... };

=head2 put

Defines a route for HTTP B<PUT> requests to the given URL:

    put '/resource' => sub { ... };

=head2 r

Defines a route pattern as a regular Perl regexp.

This method is B<DEPRECATED>. Dancer now supports real Perl Regexp objects
instead. You should not use r() but qr{} instead:

Don't do this:

    get r('/some/pattern(.*)') => sub { };

But rather this:

    get qr{/some/pattern(.*)} => sub { };

=head2 redirect

Generates a HTTP redirect (302).  You can either redirect to a complete
different site or within the application:

    get '/twitter', sub {
        redirect 'http://twitter.com/me';
    };

You can also force Dancer to return a specific 300-ish HTTP response code:

    get '/old/:resource', sub {
        redirect '/new/'.params->{resource}, 301;
    };

=head2 request

Returns a L<Dancer::Request> object representing the current request.

=head2 send_error

Returns a HTTP error.  By default the HTTP code returned is 500:

    get '/photo/:id' => sub {
        if (...) {
            send_error("Not allowed", 403);
        } else {
           # return content
        }
    }

This will not cause your route handler to return immediately, so be careful that
your route handler doesn't then override the error.  You can avoid that by
saying C<return send_error(...)> instead.


=head2 send_file

Lets the current route handler send a file to the client.

    get '/download/:file' => sub {
        send_file(params->{file});
    }

The content-type will be set depending on the current mime-types definition
(see C<mime_type> if you want to define your own).

=head2 set

Defines a setting:

    set something => 'value';

=head2 setting

Returns the value of a given setting:

    setting('something'); # 'value'

=head2 set_cookie

Creates or updates cookie values:

    get '/some_action' => sub {
        set_cookie 'name' => 'value',
            'expires' => (time + 3600),
            'domain'  => '.foo.com';
    };

In the example above, only 'name' and 'value' are mandatory.

=head2 session

Provides access to all data stored in the current
session engine (if any).

It can also be used as a setter to add new data to the current session engine:

    # getter example
    get '/user' => sub {
        if (session('user')) {
            return "Hello, ".session('user')->name;
        }
    };

    # setter example
    post '/user/login' => sub {
        ...
        if ($logged_in) {
            session user => $user;
        }
        ...
    };

You may also need to clear a session:

    # destroy session
    get '/logout' => sub {
        ...
        session->destroy;
        ...
    };

=head2 splat

Returns the list of captures made from a route handler with a route pattern
which includes wildcards:

    get '/file/*.*' => sub {
        my ($file, $extension) = splat;
        ...
    };

=head2 start

Starts the application or the standalone server (depending on the deployment
choices).

This keyword should be called at the very end of the script, once all routes
are defined.  At this point, Dancer takes over control.

=head2 status

Changes the status code provided by an action.  By default, an action will
produce an C<HTTP 200 OK> status code, meaning everything is OK:

    get '/download/:file' => {
        if (! -f params->{file}) {
            status 'not_found';
            return "File does not exist, unable to download";
        }
        # serving the file...
    };

In that example, Dancer will notice that the status has changed, and will
render the response accordingly.

The status keyword receives either a status code or its name in lower case, with
underscores as a separator for blanks.

=head2 template

Tells the route handler to build a response with the current template engine:

    get '/' => sub {
        ...
        template 'some_view', { token => 'value'};
    };

The first parameter should be a template available in the views directory, the
second one (optional) is a hashref of tokens to interpolate, and the third
(again optional) is a hashref of options.

For example, to disable the layout for a specific request:

    get '/' => sub {
        template 'index.tt', {}, { layout => undef };
    };


=head2 to_dumper ($structure)

Serializes a structure with Data::Dumper.

=head2 to_json ($structure, %options)

Serializes a structure to JSON. Can receive optional arguments. Thoses arguments are valid L<JSON> arguments to change the behavior of the default C<JSON::to_json> function.

=head2 to_yaml ($structure)

Serializes a structure to YAML.

=head2 to_xml ($structure, %options)

Serializes a structure to XML. Can receive optional arguments. Thoses arguments are valid L<XML::Simple> arguments to change the behavior of the default C<XML::Simple::XMLout> function.

=head2 true

Constant that returns a true value (1).

=head2 upload

Provides access to file uploads.  Any uploaded file is accessible as a
L<Dancer::Request::Upload> object. You can access all parsed uploads via:

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

You can also access the raw hashref of parsed uploads via the current request
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

=head2 uri_for

Returns a fully-qualified URI for the given path:

    get '/' => sub {
        redirect uri_for('/path');
        # can be something like: http://localhost:3000/path
    };

=head2 captures

Returns a reference to a copy of C<%+>, if there are named captures in the route Regexp.

Named captures are a feature of Perl 5.10, and are not supported in earlier versions:

    get qr{
        / (?<object> user   | ticket | comment )
        / (?<action> delete | find )
        / (?<id> \d+ )
        /?$
    }x
    , sub {
        my $value_for = captures;
        "i don't want to $$value_for{action} the $$value_for{object} $$value_for{id} !"
    };


=head2 var

Defines a variable shared between filters and route handlers.

    before sub {
        var foo => 42;
    };

Route handlers and other filters will be able to read that variable with the
C<vars> keyword.

=head2 vars

Returns the hashref of all shared variables set during the filter/route
chain:

    get '/path' => sub {
        if (vars->{foo} eq 42) {
            ...
        }
    };

=head2 warning

Logs a warning message through the current logger engine.

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

The following modules are mandatory (Dancer cannot run without them):

=over 8

=item L<HTTP::Server::Simple::PSGI>

=item L<HTTP::Body>

=item L<MIME::Types>

=item L<URI>

=back

The following modules are optional:

=over 8

=item L<Template> : In order to use TT for rendering views

=item L<YAML> : needed for configuration file support

=item L<File::MimeInfo::Simple>

=back


=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.


=head1 SEE ALSO

Main Dancer web site: L<http://perldancer.org/>.

The concept behind this module comes from the Sinatra ruby project,
see L<http://www.sinatrarb.com/> for details.

=cut
