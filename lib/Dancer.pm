package Dancer;

use strict;
use warnings;
use Carp;
use Cwd 'realpath';

our $VERSION   = '1.3019_01';
our $AUTHORITY = 'SUKRIA';

use Dancer::App;
use Dancer::Config;
use Dancer::Cookies;
use Dancer::FileUtils;
use Dancer::GetOpt;
use Dancer::Error;
use Dancer::Logger;
use Dancer::Renderer;
use Dancer::Route;
use Dancer::Serializer::JSON;
use Dancer::Serializer::YAML;
use Dancer::Serializer::XML;
use Dancer::Serializer::Dumper;
use Dancer::Session;
use Dancer::SharedData;
use Dancer::Handler;
use Dancer::MIME;

use File::Spec;

use base 'Exporter';

our @EXPORT    = qw(
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
  engine
  false
  forward
  from_dumper
  from_json
  from_yaml
  from_xml
  get
  halt
  header
  push_header
  headers
  layout
  load
  load_app
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
  render_with_layout
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

sub after           { Dancer::Route::Registry->hook('after', @_) }
sub any             { Dancer::App->current->registry->any_add(@_) }
sub before          { Dancer::Route::Registry->hook('before', @_) }
sub before_template { Dancer::Route::Registry->hook('before_template', @_) }
sub captures        { Dancer::SharedData->request->params->{captures} }
sub cookies         { Dancer::Cookies->cookies }
sub config          { Dancer::Config::settings() }
sub content_type    { Dancer::SharedData->response->content_type(@_) }
sub dance           { goto &start }
sub debug           { goto &Dancer::Logger::debug }
sub del             { Dancer::App->current->registry->universal_add('delete',  @_) }
sub dirname         { Dancer::FileUtils::dirname(@_) }
sub engine          { Dancer::Engine->engine(@_) }
sub error           { goto &Dancer::Logger::error }
sub false           { 0 }
sub forward         { Dancer::SharedData->response->forward(shift) }
sub from_dumper     { Dancer::Serializer::Dumper::from_dumper(@_) }
sub from_json       { Dancer::Serializer::JSON::from_json(@_) }
sub from_xml        { Dancer::Serializer::XML::from_xml(@_) }
sub from_yaml       { Dancer::Serializer::YAML::from_yaml(@_) }
sub get             { map { my $r = $_; Dancer::App->current->registry->universal_add($r, @_) } qw(head get)  }
sub halt            { Dancer::SharedData->response->halt(@_) }
sub header          { goto &headers }
sub push_header     { Dancer::SharedData->response->push_header(@_); }
sub headers         { Dancer::SharedData->response->headers(@_); }
sub layout          { set(layout => shift) }
sub load            { require $_ for @_ }
sub load_app        { goto &_load_app } # goto doesn't add a call frame. So caller() will work as expected
sub logger          { set(logger => @_) }
sub mime_type       { goto &_mime_type }
sub options         { Dancer::App->current->registry->universal_add('options', @_) }
sub params          { Dancer::SharedData->request->params(@_) }
sub pass            { Dancer::SharedData->response->pass(1) }
sub path            { realpath(Dancer::FileUtils::path(@_)) }
sub post            { Dancer::App->current->registry->universal_add('post', @_) }
sub prefix          { Dancer::App->current->set_prefix(@_) }
sub put             { Dancer::App->current->registry->universal_add('put',     @_) }
sub redirect        { goto &_redirect }
sub render_with_layout { Dancer::Template::Abstract->_render_with_layout(@_) }
sub request         { Dancer::SharedData->request }
sub send_error      { Dancer::Error->new(message => $_[0], code => $_[1] || 500)->render() }
sub send_file       { goto &_send_file }
sub set             { goto &setting }
sub set_cookie      { Dancer::Cookies->set_cookie(@_) }
sub setting         { Dancer::App->applications ? Dancer::App->current->setting(@_) : Dancer::Config::setting(@_) }
sub session         { goto &_session }
sub splat           { @{ Dancer::SharedData->request->params->{splat} || [] } }
sub start           { goto &_start }
sub status          { Dancer::SharedData->response->status(@_) }
sub template        { Dancer::Template::Abstract->template(@_) }
sub to_dumper       { Dancer::Serializer::Dumper::to_dumper(@_) }
sub to_json         { Dancer::Serializer::JSON::to_json(@_) }
sub to_xml          { Dancer::Serializer::XML::to_xml(@_) }
sub to_yaml         { Dancer::Serializer::YAML::to_yaml(@_) }
sub true            { 1 }
sub upload          { Dancer::SharedData->request->upload(@_) }
sub uri_for         { Dancer::SharedData->request->uri_for(@_) }
sub var             { Dancer::SharedData->var(@_) }
sub vars            { Dancer::SharedData->vars }
sub warning         { goto &Dancer::Logger::warning }

# When importing the package, strict and warnings pragma are loaded,
# and the appdir detection is performed.
sub import {
    my ($class, @args) = @_;
    my ($package, $script) = caller;

    strict->import;
    utf8->import;

    my @final_args;
    my $syntax_only = 0;
    my $as_script   = 0;
    foreach (@args) {
        if ( $_ eq ':moose' ) {
            push @final_args, '!before', '!after';
        }
        elsif ( $_ eq ':tests' ) {
            push @final_args, '!pass';
        }
        elsif ( $_ eq ':syntax' ) {
            $syntax_only = 1;
        }
        elsif ($_ eq ':script') {
            $as_script = 1;
        } else {
            push @final_args, $_;
        }
    }

    $class->export_to_level(1, $class, @final_args);

    # if :syntax option exists, don't change settings
    return if $syntax_only;

    Dancer::GetOpt->process_args() if !$as_script;

    _init_script_dir($script);
    Dancer::Config->load;
}

# private code

# FIXME handle previous usage of load_app with multiple app names
sub _load_app {
    my ($app_name, %options) = @_;
    my $script = (caller)[1];
    Dancer::Logger::core("loading application $app_name");

    # set the application
    my $app = Dancer::App->set_running_app($app_name);

    # Application options
    $app->prefix($options{prefix})     if $options{prefix};
    $app->settings($options{settings}) if $options{settings};

    # load the application
    _init_script_dir($script);
    my ($res, $error) = Dancer::ModuleLoader->load($app_name);
    $res or croak "unable to load application $app_name : $error";

    # restore the main application
    Dancer::App->set_running_app('main');
}

sub _init_script_dir {
    my ($script) = @_;
    
    my ($script_vol, $script_dirs, $script_name) =
      File::Spec->splitpath(File::Spec->rel2abs($script));

    # normalize
    if ( -d ( my $fulldir = File::Spec->catdir( $script_dirs, $script_name ) ) ) {
        $script_dirs = $fulldir;
        $script_name = '';
    }

    my @script_dirs = File::Spec->splitdir($script_dirs);
    my $script_path;
    if ($script_vol) {
        $script_path = Dancer::path($script_vol, $script_dirs);
    } else {
        $script_path = Dancer::path($script_dirs);
    }

    my $LAYOUT_PRE_DANCER_1_2 = 1;

    # in bin/ or public/ we need to go one level upper to find the appdir
    $LAYOUT_PRE_DANCER_1_2 = 0
      if ($script_dirs[$#script_dirs - 1] eq 'bin')
      or ($script_dirs[$#script_dirs - 1] eq 'public');

    my $appdir = $ENV{DANCER_APPDIR} || (
          $LAYOUT_PRE_DANCER_1_2
        ? $script_path
        : File::Spec->rel2abs(Dancer::path($script_path, '..'))
    );
    Dancer::setting(appdir => $appdir);

    # once the dancer_appdir have been defined, we export to env
    $ENV{DANCER_APPDIR} = $appdir;

    Dancer::Logger::core("initializing appdir to: `$appdir'");

    Dancer::setting(confdir => $ENV{DANCER_CONFDIR}
      || $appdir);

    Dancer::setting(public => $ENV{DANCER_PUBLIC}
      || Dancer::FileUtils::path_no_verify($appdir, 'public'));

    Dancer::setting(views => $ENV{DANCER_VIEWS}
      || Dancer::FileUtils::path_no_verify($appdir, 'views'));

    my ($res, $error) = Dancer::ModuleLoader->use_lib(Dancer::FileUtils::path_no_verify($appdir, 'lib'));
    $res or croak "unable to set libdir : $error";
}

sub _mime_type {
    my $mime = Dancer::MIME->instance();
      @_ == 0 ? $mime->aliases
    : @_ == 1 ? $mime->mime_type_for(@_)
    :           $mime->add_mime_type(@_);
}

sub _redirect {
    my ($destination, $status) = @_;
    if ($destination =~ m!^(\w://)?/!) {
        # no absolute uri here, build one, RFC 2616 forces us to do so
        my $request = Dancer::SharedData->request;
        $destination = $request->uri_for($destination, {}, 1);
    }
    my $response = Dancer::SharedData->response;
    $response->status($status || 302);
    $response->headers('Location' => $destination);
}

sub _session {
    engine 'session'
      or croak "Must specify session engine in settings prior to using 'session' keyword";
      @_ == 0 ? Dancer::Session->get
    : @_ == 1 ? Dancer::Session->read(@_)
    :           Dancer::Session->write(@_);
}

sub _send_file {
    my ($path) = @_;

    my $request = Dancer::Request->new_for_request('GET' => $path);
    Dancer::SharedData->request($request);

    my $resp = Dancer::Renderer::get_file_response();
    return $resp if $resp;

    Dancer::Error->new(
        code    => 404,
        message => "No such file: `$path'"
    )->render();
    
}

# Start/Run the application with the chosen apphandler
sub _start {
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

=head1 MORE DOCUMENTATION

This documentation describes all the exported symbols of Dancer. If you want
a quick start guide to discover the framework, you should look at
L<Dancer::Introduction>, or L<Dancer::Tutorial> to learn by example.

If you want to have specific examples of code for real-life problems, see the
L<Dancer::Cookbook>.

If you want to see configuration examples of different deployment solutions
involving Dancer and Plack, see L<Dancer::Deployment>.

You can find out more about the many useful plugins available for Dancer in
L<Dancer::Plugins>.


=head1 EXPORTS

By default, C<use Dancer> exports all the functions below plus sets up
your app.  You can control the exporting through the normal
L<Exporter> means.  For example:

    # Just export the route controllers
    use Dancer qw(before after get post);

    # Export everything but pass to avoid clashing with Test::More
    use Test::More;
    use Dancer qw(!pass);

There are also some special tags to control exports and behavior.

=head2 :moose

This will export everything except those functions which clash with
Moose.  Currently that is L<after> and L<before>.

=head2 :syntax

This tells Dancer to just export symbols and not set up your app.
This is most useful for writing Dancer code outside of your main route
handler.

=head2 :tests

This will export everything except those functions which clash with
commonly used testing modules.  Currently that is L<pass>.

These can be combined.  For example, while testing...

    use Test::More;
    use Dancer qw(:syntax :tests);

    # Test::Most also exports "set" and "any"
    use Test::Most;
    use Dancer qw(:syntax :tests !set !any);

    # Alternatively, if you want to use Dancer's set and any...
    use Test::Most qw(!set !any);
    use Dancer qw(:syntax :tests);

=head2 :script

This will export all the keywords, and will also load the configuration.

This is useful when you want to use your Dancer application from a script.

    use MyApp;
    use Dancer ':script';
    MyApp::schema('DBSchema')->deploy();

=head1 FUNCTIONS

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
executing a route handler to handle the request.

If the function modifies the request's C<path_info> or C<method>, a new
search for a matching route is performed and the filter is re-executed
again. Considering that this can lead to an infinite loop, this mechanism
is stopped after 10 times with an exception.

The before filter can set a response with a redirection code (either
301 or 302): in this case the matched route (if any) will be ignored and the
redirection will be performed immediately.

You can define multiple before filters, using the C<before> helper as
many times as you wish; each filter will be executed in the order you added
them.

=head2 before_template

Defines a before_template filter:

    before_template sub {
        my $tokens = shift;
        # do something with request, vars or params
    };

The anonymous function which is given to C<before_template> will be executed
before sending data and tokens to the template. Receives a hashref of the
tokens that will be inserted into the template.

This filter works as the C<before> and C<after> filter.

=head2 cookies

Accesses cookies values, which returns a hashref of L<Dancer::Cookie> objects:

    get '/some_action' => sub {
        my $cookie = cookies->{name};
        return $cookie->value;
    };

In the case you have stored something else than a scalar in your cookie:

    get '/some_action' => sub {
        my $cookie = cookies->{oauth};
        my %values = $cookie->value;
        return ($values{token}, $values{token_secret});
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

You can use abbreviations for content types. For instance:

    get '/svg/:id' => sub {
        content_type 'svg';

        # here we can dump the image with id params->{id}
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

=head2 engine

Given an namespace, returns the current engine object

    my $template_engine = engine 'template';
    my $html = $template_engine->apply_renderer(...);
    $template_engine->apply_layout($html);

=head2 error

Logs a message of error level:

    error "This is an error message";

=head2 false

Constant that returns a false value (0).

=head2 forward

Runs an internal redirect of the current request to another request. This helps
you avoid having to redirect the user using HTTP and set another request to your
application.

It effectively lets you chain routes together in a clean manner.

    get qr{ /demo/articles/(.+) }x => sub {
        my ($article_id) = splat;

        # you'll have to implement this next sub yourself :)
        change_the_main_database_to_demo();

        forward '/articles/$article_id';
    };

In the above example, the users that reach I</demo/articles/30> will actually
reach I</articles/30> but we've changed the database to demo before.

This is pretty cool because it lets us retain our paths and offer a demo
database by merely going to I</demo/...>.

You'll notice that in the example we didn't indicate whether it was B<GET> or
B<POST>. That is because C<forward> chains the same type of route the user
reached. If it was a B<GET>, it will remain a B<GET>.

Broader functionality might be added in the future.

It is important to note that issuing a forward by itself does not exit and
forward immediately, forwarding is deferred until after the current route
or filter has been processed. To exit and forward immediately, use the return
function, e.g.

    get '/some/path => sub {
        if ($condition) {
            return forward '/articles/$article_id';
        }

        more_stuff();
    };

You probably always want to use C<return> with forward.

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
renders the response immediately:

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

adds a custom header to response:

    get '/send/header', sub {
        header 'x-my-header' => 'shazam!';
    }

=head2 push_header

Do the same as C<header>, but allow for multiple headers with the same name.

    get '/send/header', sub {
        push_header 'x-my-header' => '1';
        push_header 'x-my-header' => '2';
        will result in two headers "x-my-header" in the response
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

=head2 mime_type

Returns all the user-defined mime-types when called without parameters.
Behaves as a setter/getter when given parameters

    # get the global hash of user-defined mime-types:
    my $mimes = mime_type;

    # set a mime-type
    mime_type foo => 'text/foo';

    # get a mime-type
    my $m = mime_type 'foo';

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
    
It is important to note that issuing a redirect by itself does not exit and
redirect immediately, redirection is deferred until after the current route
or filter has been processed. To exit and redirect immediately, use the return
function, e.g.

    get '/restricted', sub {
        return redirect '/login' if accessDenied();
        return 'Welcome to the restricted section';
    };

=head2 render_with_layout

Allows a handler to provide plain HTML (or other content), but have it rendered
within the layout still.

This method is B<DEPRECATED>, and will be removed soon. Instead, you should be
using the C<engine> keyword:

    get '/foo' => sub {
        # Do something which generates HTML directly (maybe using
        # HTML::Table::FromDatabase or something)
        my $content = ...;

        # get the template engine
        my $template_engine = engine 'template';

        # apply the layout (not the renderer), and return the result
        $template_engine->apply_layout($content)
    };

It works very similarly to C<template> in that you can pass tokens to be used in
the layout, and/or options to control the way the layout is rendered.  For
instance, to use a custom layout:

    render_with_layout $content, {}, { layout => 'layoutname' };


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

The path of the file must be relative to the B<public> directory.

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

You can also store more complex structure in your cookies:

    get '/some_auth' => sub {
        set_cookie oauth => {
            token        => $twitter->request_token,
            token_secret => $twitter->secret_token,
            ...
        };
    };

You can't store more complex structure than this. All your keys in your hash should be scalar.

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

If you don't have an IRC client installed/configured, there is a simple web chat
client at L<http://www.perldancer.org/irc> for you.

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
