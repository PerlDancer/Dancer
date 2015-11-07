package Dancer;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: lightweight yet powerful web application framework
$Dancer::VERSION = '1.3202';
use strict;
use warnings;
use Carp;
use Cwd 'realpath';

use Dancer::App;
use Dancer::Config;
use Dancer::Cookies;
use Dancer::FileUtils;
use Dancer::GetOpt;
use Dancer::Error;
use Dancer::Hook;
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
use Dancer::Exception qw(:all);

use Dancer::Continuation::Halted;
use Dancer::Continuation::Route::Forwarded;
use Dancer::Continuation::Route::Passed;
use Dancer::Continuation::Route::ErrorSent;
use Dancer::Continuation::Route::FileSent;
use Dancer::Continuation::Route::Templated;

use File::Spec;
use Scalar::Util;

use base 'Exporter';

our @EXPORT    = qw(
  after
  any
  before
  before_template
  cookie
  cookies
  config
  content_type
  dance
  dancer_version
  debug
  del
  dirname
  info
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
  headers
  hook
  layout
  load
  load_app
  logger
  mime
  options
  param
  param_array
  params
  pass
  path
  patch
  post
  prefix
  push_header
  put
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

sub after           {
    Dancer::Deprecation->deprecated(reason => "use hooks!",
                                    version => '1.3080',
                                    fatal => 0);
    Dancer::Hook->new('after', @_);
}
sub before          {
    Dancer::Deprecation->deprecated(reason => "use hooks!",
                                    version => '1.3080',
                                    fatal => 0);
    Dancer::Hook->new('before', @_);
}
sub before_template {
    Dancer::Deprecation->deprecated(reason => "use hooks!",
                                    version => '1.3080',
                                    fatal => 0);
    Dancer::Hook->new('before_template', @_);
}

sub any             { Dancer::App->current->registry->any_add(@_) }
sub captures        { Dancer::SharedData->request->params->{captures} }
sub cookie          { Dancer::Cookies->cookie( @_ ) }
sub cookies         { Dancer::Cookies->cookies }
sub config          { Dancer::Config::settings() }
sub content_type    { Dancer::SharedData->response->content_type(@_) }
sub dance           { goto &start }
sub dancer_version  { Dancer->VERSION }
sub debug           { goto &Dancer::Logger::debug }
sub del             { Dancer::App->current->registry->universal_add('delete',  @_) }
sub dirname         { Dancer::FileUtils::dirname(@_) }
sub engine          { Dancer::Engine->engine(@_) }
sub error           { goto &Dancer::Logger::error }
sub false           { 0 }
sub forward         { Dancer::SharedData->response->forward(@_);
                      # throw a special continuation exception
                      Dancer::Continuation::Route::Forwarded->new->throw;
                    }
sub from_dumper     { Dancer::Serializer::Dumper::from_dumper(@_) }
sub from_json       { Dancer::Serializer::JSON::from_json(@_) }
sub from_xml        { Dancer::Serializer::XML::from_xml(@_) }
sub from_yaml       { Dancer::Serializer::YAML::from_yaml(@_) }
sub get             { map { my $r = $_; Dancer::App->current->registry->universal_add($r, @_) } qw(head get)  }
sub halt            { Dancer::SharedData->response->halt(@_);
                      # throw a special continuation exception
                      Dancer::Continuation::Halted->new->throw;
                    }
sub header          { goto &headers }
sub info            { goto &Dancer::Logger::info }
sub push_header     { Dancer::SharedData->response->push_header(@_); }
sub headers         { Dancer::SharedData->response->headers(@_); }
sub hook            { Dancer::Hook->new(@_) }
sub layout          {
    Dancer::Deprecation->deprecated(reason => "use 'set layout => \"value\"'",
                                    version => '1.3050',
                                    fatal => 1);
}
sub load            { require $_ for @_ }
sub load_app        { goto &_load_app } # goto doesn't add a call frame. So caller() will work as expected
sub logger          {
    Dancer::Deprecation->deprecated(reason => "use 'set logger => \"value\"'",
                                    fatal => 1,version=>'1.3050');
}
sub mime            { Dancer::MIME->instance() }
sub options         { Dancer::App->current->registry->universal_add('options', @_) }
sub params          { Dancer::SharedData->request->params(@_) }
sub param           { params->{$_[0]} }
sub param_array     { 
    my $value = param(shift);

    my @array = ref $value eq 'ARRAY' ? @$value 
              : defined $value        ? ( $value ) 
              :                         ()
              ;

    return @array;
}
sub pass            { Dancer::SharedData->response->pass(1);
                      # throw a special continuation exception
                      Dancer::Continuation::Route::Passed->new->throw;
                    }
sub patch            { Dancer::App->current->registry->universal_add('patch', @_) }
sub path            { Dancer::FileUtils::path(@_) }
sub post            { Dancer::App->current->registry->universal_add('post', @_) }
sub prefix          { @_ == 0 ? Dancer::App->current->get_prefix :
                          Dancer::App->current->set_prefix(@_) }
sub put             { Dancer::App->current->registry->universal_add('put',     @_) }
sub redirect        { goto &_redirect }
sub render_with_layout { Dancer::Template::Abstract->_render_with_layout(@_) }
sub request         { Dancer::SharedData->request }
sub send_error      { Dancer::Continuation::Route::ErrorSent->new(
                          return_value => Dancer::Error->new(
                              message => $_[0],
                              code => $_[1] || 500)->render()
                      )->throw }
#sub send_file       { goto &_send_file }
sub send_file       { Dancer::Continuation::Route::FileSent->new(
                          return_value => _send_file(@_)
                      )->throw
                    }
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
{
    my $as_script   = 0;

sub import {
    my ($class, @args) = @_;
    my ($package, $script) = caller;

    strict->import;
    warnings->import;
    utf8->import;

    my @final_args;
    my $syntax_only = 0;
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

    $as_script = 1 if $ENV{PLACK_ENV};

    Dancer::GetOpt->process_args unless $as_script;

    _init_script_dir($script);
    Dancer::Config->load;
}

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
    $app->set_app_prefix($options{prefix}) if $options{prefix};
    $app->settings($options{settings}) if $options{settings};

    # load the application
    _init_script_dir($script);
    my ($res, $error) = Dancer::ModuleLoader->load($app_name);
    $res or raise core => "unable to load application $app_name : $error";

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

    # in bin/ or public/ or t/ we need to go one level up to find the appdir
    $LAYOUT_PRE_DANCER_1_2 = 0
      if ($script_dirs[$#script_dirs - 1] eq 'bin')
      or ($script_dirs[$#script_dirs - 1] eq 'public')
      or ($script_dirs[$#script_dirs - 1] eq 't');

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
      || $appdir) unless Dancer::setting('confdir');

    Dancer::setting(public => $ENV{DANCER_PUBLIC}
      || Dancer::FileUtils::path($appdir, 'public'));

    Dancer::setting(views => $ENV{DANCER_VIEWS}
      || Dancer::FileUtils::path($appdir, 'views'));

    my ($res, $error) = Dancer::ModuleLoader->use_lib(Dancer::FileUtils::path($appdir, 'lib'));
    $res or raise core => "unable to set libdir : $error";
}


# Scheme grammar as defined in RFC 2396
#  scheme = alpha *( alpha | digit | "+" | "-" | "." )
my $scheme_re = qr{ [a-z][a-z0-9\+\-\.]* }ix;
sub _redirect {
    my ($destination, $status) = @_;

    # RFC 2616 requires an absolute URI with a scheme,
    # turn the URI into that if it needs it
    if ($destination !~ m{^ $scheme_re : }x) {
        my $request = Dancer::SharedData->request;
        $destination = $request->uri_for($destination, {}, 1);
    }
    my $response = Dancer::SharedData->response;
    $response->status($status || 302);
    $response->headers('Location' => $destination);
}

sub _session {
    engine 'session'
      or raise core => "Must specify session engine in settings prior to using 'session' keyword";
      @_ == 0 ? Dancer::Session->get
    : @_ == 1 ? Dancer::Session->read(@_)
    :           Dancer::Session->write(@_);
}

sub _send_file {
    my ($path, %options) = @_;
    my $env = Dancer::SharedData->request->env;

    my $request = Dancer::Request->new_for_request('GET' => $path);
    Dancer::SharedData->request($request);

    # if you asked for streaming but it's not supported in PSGI
    if ( $options{'streaming'} && ! $env->{'psgi.streaming'} ) {
        # TODO: throw a fit (AKA "exception") or a Dancer::Error?
        raise core => 'Sorry, streaming is not supported on this server.';
    }

    if (exists($options{content_type})) {
        $request->content_type($options{content_type});
    }

    # If we're given an IO::Scalar object, DTRT (take the scalar ref from it)
    if (Scalar::Util::blessed($path) && $path->isa('IO::Scalar')) {
        $path = $path->sref;
    }

    my $resp;
    if (ref($path) eq "SCALAR") {
        # send_data
        $resp = Dancer::SharedData->response() || Dancer::Response->new();
        $resp->header('Content-Type' => exists($options{content_type}) ?
                                        $options{content_type} : Dancer::MIME->default());
        $resp->content($$path);
    } else {
        # real send_file
        if ($options{system_path} && -f $path) {
            $resp = Dancer::Renderer->get_file_response_for_path($path);
        } else {
            $resp = Dancer::Renderer->get_file_response();
        }
    }

    if ($resp) {

        if (exists($options{filename})) {
            $resp->push_header('Content-Disposition' => 
                "attachment; filename=\"$options{filename}\""
            );
        }

        if ( $options{'streaming'} ) {
            # handle streaming
            $resp->streamed( sub {
                my ( $status, $headers ) = @_;
                my %callbacks = defined $options{'callbacks'} ?
                                %{ $options{'callbacks'} }    :
                                ();

                return sub {
                    my $respond = shift;
                    exists $callbacks{'override'}
                        and return $callbacks{'override'}->( $respond, $resp );

                    # get respond callback and set headers, get writer in return
                    my $writer = $respond->( [
                        $status,
                        $headers,
                    ] );

                    # get content from original response
                    my $content = $resp->content;

                    exists $callbacks{'around'}
                        and return $callbacks{'around'}->( $writer, $content );

                    if ( ref $content ) {
                        my $bytes = $options{'bytes'} || '43008'; # 42K (dams)
                        my $buf;
                        while ( ( my $read = sysread $content, $buf, $bytes ) != 0 ) {
                            if ( exists $callbacks{'around_content'} ) {
                                $callbacks{'around_content'}->( $writer, $buf );
                            } else {
                                $writer->write($buf);
                            }
                        }
                    } else {
                        $writer->write($content);
                    }
                };
            } );
        }

        return $resp;

    }

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
        Dancer::Handler->init_request_headers( $request->env );
        # TODO _build_headers should either not be private, or we should call
        # init
        $request->_build_headers;
        return Dancer::Handler->handle_request($request);
    }

    my $handler = Dancer::Handler->get_handler;
    Dancer::Logger::core("loading handler '".ref($handler)."'");
    return $handler->dance;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer - lightweight yet powerful web application framework

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

    #!/usr/bin/perl
    use Dancer;

    get '/hello/:name' => sub {
        return "Why, hello there " . param('name');
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

Dancer apps can be used with an embedded web server (great for easy testing),
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
L<Exporter> mechanism.  For example:

    # Just export the route controllers
    use Dancer qw(get post put patch del);

    # Export everything but pass to avoid clashing with Test::More
    use Test::More;
    use Dancer qw(!pass);

Please note that the L<utf8> and L<strict> pragmas are exported by this module.

By default, the L<warnings> pragma will also be exported, meaning your
app/script will be running under C<use warnings>.  If you do not want this, set
the L<global_warnings|Dancer::Config/global_warnings> setting to a false value.

There are also some special tags to control exports and behaviour.

=head2 :moose

This will export everything except functions which clash with
Moose. Currently these are C<after> and C<before>.

=head2 :syntax

This tells Dancer to just export symbols and not set up your app.
This is most useful for writing Dancer code outside of your main route
handler.

=head2 :tests

This will export everything except functions which clash with
commonly used testing modules. Currently these are C<pass>.

It can be combined with other export pragmas. For example, while testing...

    use Test::More;
    use Dancer qw(:syntax :tests);

    # Test::Most also exports "set" and "any"
    use Test::Most;
    use Dancer qw(:syntax :tests !set !any);

    # Alternatively, if you want to use Dancer's set and any...
    use Test::Most qw(!set !any);
    use Dancer qw(:syntax :tests);

=head2 :script

This will export all the keywords, load the configuration,
and will not try to parse command-line arguments via L<Dancer::GetOpt>.

This is useful when you want to use your Dancer application from a script.

    use MyApp;
    use Dancer ':script';
    MyApp::schema('DBSchema')->deploy();

Note that using C<:script>  will disable command-line parsing for all 
subsequent invocations of C<use Dancer> (such that you don't have to
use C<:script> for each and every module to make sure the command-line
arguments don't get stolen by Dancer).

=head2 !keyword

If you want to simply prevent Dancer from exporting specific keywords (perhaps
you plan to implement them yourself in a different way, or you don't plan to use
them and they clash with another module you're loading), you can simply exclude
them:

    use Dancer qw(!session);

The above would import all keywords as normal, with the exception of C<session>.

=head1 FUNCTIONS

=head2 after

Deprecated - see the C<after> L<hook|Dancer/hook>.

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

Deprecated - see the C<before> L<hook|Dancer/hook>.

=head2 before_template

Deprecated - see the C<before_template> L<hook|Dancer/hook>.

=head2 cookies

Accesses cookies values, it returns a HashRef of L<Dancer::Cookie> objects:

    get '/some_action' => sub {
        my $cookie = cookies->{name};
        return $cookie->value;
    };

In the case you have stored something other than a Scalar in your cookie:

    get '/some_action' => sub {
        my $cookie = cookies->{oauth};
        my %values = $cookie->value;
        return ($values{token}, $values{token_secret});
    };

=head2 cookie

Accesses a cookie value (or sets it). Note that this method will
eventually be preferred over C<set_cookie>.

    cookie lang => "fr-FR";              # set a cookie and return its value
    cookie lang => "fr-FR", expires => "2 hours";   # extra cookie info
    cookie "lang"                        # return a cookie value

If your cookie value is a key/value URI string, like

    token=ABC&user=foo

C<cookie> will only return the first part (C<token=ABC>) if called in scalar context.
Use list context to fetch them all:

    my @values = cookie "name";

=head2 config

Accesses the configuration of the application:

    get '/appname' => sub {
        return "This is " . config->{appname};
    };

=head2 content_type

Sets the B<content-type> rendered, for the current route handler:

    get '/cat/:txtfile' => sub {
        content_type 'text/plain';

        # here we can dump the contents of param('txtfile')
    };

You can use abbreviations for content types. For instance:

    get '/svg/:id' => sub {
        content_type 'svg';

        # here we can dump the image with id param('id')
    };

Note that if you want to change the default content-type for every route, you
have to change the C<content_type> setting instead.

=head2 dance

Alias for the C<start> keyword.

=head2 dancer_version

Returns the version of Dancer. If you need the major version, do something like:

  int(dancer_version);

=head2 debug

Logs a message of debug level:

    debug "This is a debug message";

See L<Dancer::Logger> for details on how to configure where log messages go.

=head2 dirname

Returns the dirname of the path given:

    my $dir = dirname($some_path);

=head2 engine

Given a namespace, returns the current engine object

    my $template_engine = engine 'template';
    my $html = $template_engine->apply_renderer(...);
    $template_engine->apply_layout($html);

=head2 error

Logs a message of error level:

    error "This is an error message";

See L<Dancer::Logger> for details on how to configure where log messages go.

=head2 false

Constant that returns a false value (0).

=head2 forward

Runs an internal redirect of the current request to another request. This helps
you avoid having to redirect the user using HTTP and set another request to your
application.

It effectively lets you chain routes together in a clean manner.

    get '/demo/articles/:article_id' => sub {

        # you'll have to implement this next sub yourself :)
        change_the_main_database_to_demo();

        forward "/articles/" . params->{article_id};
    };

In the above example, the users that reach I</demo/articles/30> will actually
reach I</articles/30> but we've changed the database to demo before.

This is pretty cool because it lets us retain our paths and offer a demo
database by merely going to I</demo/...>.

You'll notice that in the example we didn't indicate whether it was B<GET> or
B<POST>. That is because C<forward> chains the same type of route the user
reached. If it was a B<GET>, it will remain a B<GET> (but if you do need to
change the method, you can do so; read on below for details.)

B<WARNING> : using forward will B<not> preserve session data set on
the forwarding rule.

B<WARNING> : Issuing a forward immediately exits the current route,
and perform the forward. Thus, any code after a forward is ignored, until the
end of the route. e.g.

    get '/foo/:article_id' => sub {
        if ($condition) {
            forward "/articles/" . params->{article_id};
            # The following code is never executed
            do_stuff();
        }

        more_stuff();
    };

So it's not necessary anymore to use C<return> with forward.

Note that forward doesn't parse GET arguments. So, you can't use
something like:

     return forward '/home?authorized=1';

But C<forward> supports an optional HashRef with parameters to be added
to the actual parameters:

     return forward '/home', { authorized => 1 };

Finally, you can add some more options to the forward method, in a
third argument, also as a HashRef. That option is currently
only used to change the method of your request. Use with caution.

    return forward '/home', { auth => 1 }, { method => 'POST' };

=head2 from_dumper ($structure)

Deserializes a L<< Data::Dumper >> structure.

=head2 from_json ($structure, %options)

Deserializes a JSON structure. Can receive optional arguments. Those arguments
are valid L<JSON> arguments to change the behaviour of the default
C<JSON::from_json> function.

=head2 from_yaml ($structure)

Deserializes a YAML structure.

=head2 from_xml ($structure, %options)

Deserializes a XML structure. Can receive optional arguments. These arguments
are valid L<XML::Simple> arguments to change the behaviour of the default
C<XML::Simple::XMLin> function.

=head2 get

Defines a route for HTTP B<GET> requests to the given path:

    get '/' => sub {
        return "Hello world";
    }

Note that a route to match B<HEAD> requests is automatically created as well.

=head2 halt

Sets a response object with the content given.

When used as a return value from a filter, this breaks the execution flow and
renders the response immediately:

    hook before sub {
        if ($some_condition) {
            halt("Unauthorized");
            # This code is not executed :
            do_stuff();
        }
    };

    get '/' => sub {
        "hello there";
    };

B<WARNING> : Issuing a halt immediately exits the current route, and perform
the halt. Thus, any code after a halt is ignored, until the end of the route.
So it's not necessary anymore to use C<return> with halt.

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

Note that it will overwrite the old value of the header, if any. To avoid that,
see L</push_header>.

=head2 push_header

Do the same as C<header>, but allow for multiple headers with the same name.

    get '/send/header', sub {
        push_header 'x-my-header' => '1';
        push_header 'x-my-header' => '2';
        will result in two headers "x-my-header" in the response
    }

=head2 hook

Adds a hook at some position. For example :

  hook before_serializer => sub {
    my $response = shift;
    $response->content->{generated_at} = localtime();
  };

There can be multiple hooks assigned to a given position, and each will be
executed in order. Note that B<all> hooks are always called, even if they
are defined in a different package loaded via C<load_app>.

(For details on how to register new hooks from within plugins, see
L<Dancer::Hook>.)
Supported B<before> hooks (in order of execution):

=over

=item before_deserializer

This hook receives no arguments.

  hook before_deserializer => sub {
    ...
  };

=item before_file_render

This hook receives as argument the path of the file to render.

  hook before_file_render => sub {
    my $path = shift;
    ...
  };

=item before_error_init

This hook receives as argument a L<Dancer::Error> object.

  hook before_error_init => sub {
    my $error = shift;
    ...
  };

=item before_error_render

This hook receives as argument a L<Dancer::Error> object.

  hook before_error_render => sub {
    my $error = shift;
  };

=item before

This hook receives one argument, the route being executed (a L<Dancer::Route>
object).

  hook before => sub {
    my $route_handler = shift;
    ...
  };

it is equivalent to the deprecated

  before sub {
    ...
  };

=item before_template_render

This is an alias to 'before_template'.

This hook receives as argument a HashRef containing the tokens that
will be passed to the template. You can use it to add more tokens, or
delete some specific token.

  hook before_template_render => sub {
    my $tokens = shift;
    delete $tokens->{user};
    $tokens->{time} = localtime;
  };

is equivalent to

  hook before_template => sub {
    my $tokens = shift;
    delete $tokens->{user};
    $tokens->{time} = localtime;
  };

=item before_layout_render

This hook receives two arguments. The first one is a HashRef containing the
tokens. The second is a ScalarRef representing the content of the template.

  hook before_layout_render => sub {
    my ($tokens, $html_ref) = @_;
    ...
  };

=item before_serializer

This hook receives as argument a L<Dancer::Response> object.

  hook before_serializer => sub {
    my $response = shift;
    $response->content->{start_time} = time();
  };

=back

Supported B<after> hooks (in order of execution):

=over

=item after_deserializer

This hook receives no arguments.

  hook after_deserializer => sub {
    ...
  };

=item after_file_render

This hook receives as argument a L<Dancer::Response> object.

  hook after_file_render => sub {
    my $response = shift;
  };

=item after_template_render

This hook receives as argument a ScalarRef representing the content generated
by the template.

  hook after_template_render => sub {
    my $html_ref = shift;
  };

=item after_layout_render

This hook receives as argument a ScalarRef representing the content generated
by the layout

  hook after_layout_render => sub {
    my $html_ref = shift;
  };

=item after

This is an alias for C<after>.

This hook runs after a request has been processed, but before the response is
sent.

It receives a L<Dancer::Response> object, which it can modify
if it needs to make changes to the response which is about to be sent.

  hook after => sub {
    my $response = shift;
  };

This is equivalent to the deprecated

  after sub {
    my $response = shift;
  };

=item after_error_render

This hook receives as argument a L<Dancer::Response> object.

  hook after_error_render => sub {
    my $response = shift;
  };

=item on_handler_exception

This hook is called when an exception has been caught, at the handler level,
just before creating and rendering L<Dancer::Error>. This hook receives as
argument a L<Dancer::Exception> object.

  hook on_handler_exception => sub {
    my $exception = shift;
  };

=item on_reset_state

This hook is called when global state is reset to process a new request.
It receives a boolean value that indicates whether the reset was called
as part of a forwarded request.

  hook on_reset_state => sub {
    my $is_forward = shift;
  };

=item on_route_exception

This hook is called when an exception has been caught, at the route level, just
before rethrowing it higher. This hook receives the exception as argument. It
can be a Dancer::Exception, or a string, or whatever was used to C<die>.

  hook on_route_exception => sub {
    my $exception = shift;
  };

=back

=head2 info

Logs a message of info level:

    info "This is a info message";

See L<Dancer::Logger> for details on how to configure where log messages go.

=head2 layout

This method is deprecated. Use C<set>:

    set layout => 'user';

=head2 logger

Deprecated. Use C<<set logger =E<gt> 'console'>> to change current logger engine.

=head2 load

Loads one or more perl scripts in the current application's namespace. Syntactic
sugar around Perl's C<require>:

    load 'UserActions.pl', 'AdminActions.pl';

=head2 load_app

Loads a Dancer package. This method sets the libdir to the current C<./lib>
directory:

    # if we have lib/Webapp.pm, we can load it like:
    load_app 'Webapp';
    # or with options
    load_app 'Forum', prefix => '/forum', settings => {foo => 'bar'};

Note that the package loaded using load_app B<must> import Dancer with the
C<:syntax> option.

To load multiple apps repeat load_app:

    load_app 'one';
    load_app 'two';

The old way of loading multiple apps in one go (load_app 'one', 'two';) is
deprecated.

=head2 mime

Shortcut to access the instance object of L<Dancer::MIME>. You should
read the L<Dancer::MIME> documentation for full details, but the most
commonly-used methods are summarized below:

    # set a new mime type
    mime->add_type( foo => 'text/foo' );

    # set a mime type alias
    mime->add_alias( f => 'foo' );

    # get mime type for an alias
    my $m = mime->for_name( 'f' );

    # get mime type for a file (based on extension)
    my $m = mime->for_file( "foo.bar" );

    # get current defined default mime type
    my $d = mime->default;

    # set the default mime type using config.yml
    # or using the set keyword
    set default_mime_type => 'text/plain';

=head2 params

I<This method should be called from a route handler>.
It's an alias for the L<Dancer::Request params
accessor|Dancer::Request/"params-source">. In list context it returns a
list of key/value pair of all defined parameters. In scalar context
it returns a hash reference instead.
Check C<param> below to access quickly to a single
parameter value.

=head2 param

I<This method should be called from a route handler>.
This method is an accessor to the parameters hash table.

   post '/login' => sub {
       my $username = param "user";
       my $password = param "pass";
       # ...
   }

=head2 param_array

I<This method should be called from a route handler>.
Like I<param>, but always returns the parameter value or values as a list.
Returns the number of values in scalar context.

    # if request is '/tickets?tag=open&tag=closed&order=desc'...
    get '/tickets' => sub {
        my @tags = param_array 'tag';  # ( 'open', 'closed' )
        my $tags = param 'tag';        # array ref

        my @order = param_array 'order';  # ( 'desc' )
        my $order = param 'order';        # 'desc'
    };

=head2 pass

I<This method should be called from a route handler>.
Tells Dancer to pass the processing of the request to the next
matching route.

B<WARNING> : Issuing a pass immediately exits the current route, and performs
the pass. Thus, any code after a pass is ignored until the end of the route.
So it's not necessary any more to use C<return> with pass.

    get '/some/route' => sub {
        if (...) {
            # we want to let the next matching route handler process this one
            pass(...);
            # This code will be ignored
            do_stuff();
        }
    };

=head2 patch

Defines a route for HTTP B<PATCH> requests to the given URL:

    patch '/resource' => sub { ... };

(C<PATCH> is a relatively new and not-yet-common HTTP verb, which is intended to
work as a "partial-PUT", transferring just the changes; please see
L<http://tools.ietf.org/html/rfc5789|RFC5789> for further details.)

Please be aware that, if you run your app in standalone mode, C<PATCH> requests
will not reach your app unless you have a new version of L<HTTP::Server::Simple>
which accepts C<PATCH> as a valid verb.  The current version at time of writing,
C<0.44>, does not.  A pull request has been submitted to add this support, which
you can find at:

L<https://github.com/bestpractical/http-server-simple/pull/1>

=head2 path

Concatenates multiple paths together, without worrying about the underlying
operating system:

    my $path = path(dirname($0), 'lib', 'File.pm');

It also normalizes (cleans) the path aesthetically. It does not verify the
path exists.

=head2 post

Defines a route for HTTP B<POST> requests to the given URL:

    post '/' => sub {
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

For a safer alternative you can use lexical prefix like this:

    prefix '/home' => sub {
        ## Prefix is set to '/home' here

        get ...;
        get ...;
    };
    ## prefix reset to the previous version here

This makes it possible to nest prefixes:

   prefix '/home' => sub {
       ## some routes
       
      prefix '/private' => sub {
         ## here we are under /home/private...

         ## some more routes
      };
      ## back to /home
   };
   ## back to the root

B<Notice:> once you have a prefix set, do not add a caret to the regex:

    prefix '/foo';
    get qr{^/bar} => sub { ... } # BAD BAD BAD
    get qr{/bar}  => sub { ... } # Good!

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

Generates an HTTP redirect (302).  You can either redirect to a completely
different site or within the application:

    get '/twitter', sub {
        redirect 'http://twitter.com/me';
    };

You can also force Dancer to return a specific 300-ish HTTP response code:

    get '/old/:resource', sub {
        redirect '/new/'.params->{resource}, 301;
    };

It is important to note that issuing a redirect by itself does not exit and
redirect immediately. Redirection is deferred until after the current route
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

See the L<Dancer::Request> documentation for the methods you can call, for
example:

    request->referer;         # value of the HTTP referer header
    request->remote_address;  # user's IP address
    request->user_agent;      # User-Agent header value

=head2 send_error

Returns an HTTP error.  By default the HTTP code returned is 500:

    get '/photo/:id' => sub {
        if (...) {
            send_error("Not allowed", 403);
        } else {
           # return content
        }
    }

B<WARNING> : Issuing a send_error immediately exits the current route, and perform
the send_error. Thus, any code after a send_error is ignored, until the end of the route.
So it's not necessary anymore to use C<return> with send_error.

    get '/some/route' => sub {
        if (...) {
            # we want to let the next matching route handler process this one
            send_error(..);
            # This code will be ignored
            do_stuff();
        }
    };

=head2 send_file

Lets the current route handler send a file to the client. Note that
the path of the file must be relative to the B<public> directory unless you use
the C<system_path> option (see below).

    get '/download/:file' => sub {
        send_file(params->{file});
    }

B<WARNING> : Issuing a send_file immediately exits the current route, and performs
the send_file. Thus, any code after a send_file is ignored until the end of the route.
So it's not necessary any more to use C<return> with send_file.

    get '/some/route' => sub {
        if (...) {
            # we want to let the next matching route handler process this one
            send_file(...);
            # This code will be ignored
            do_stuff();
        }
    };

Send file supports streaming possibility using PSGI streaming. The server should
support it but normal streaming is supported on most, if not all.

    get '/download/:file' => sub {
        send_file( params->{file}, streaming => 1 );
    }

You can control what happens using callbacks.

First, C<around_content> allows you to get the writer object and the chunk of
content read, and then decide what to do with each chunk:

    get '/download/:file' => sub {
        send_file(
            params->{file},
            streaming => 1,
            callbacks => {
                around_content => sub {
                    my ( $writer, $chunk ) = @_;
                    $writer->write("* $chunk");
                },
            },
        );
    }

You can use C<around> to all get all the content (whether a filehandle if it's
a regular file or a full string if it's a scalar ref) and decide what to do with
it:

    get '/download/:file' => sub {
        send_file(
            params->{file},
            streaming => 1,
            callbacks => {
                around => sub {
                    my ( $writer, $content ) = @_;

                    # we know it's a text file, so we'll just stream
                    # line by line
                    while ( my $line = <$content> ) {
                        $writer->write($line);
                    }
                },
            },
        );
    }

Or you could use C<override> to control the entire streaming callback request:

    get '/download/:file' => sub {
        send_file(
            params->{file},
            streaming => 1,
            callbacks => {
                override => sub {
                    my ( $respond, $response ) = @_;

                    my $writer = $respond->( [ $newstatus, $newheaders ] );
                    $writer->write("some line");
                },
            },
        );
    }

You can also set the number of bytes that will be read at a time (default being
42K bytes) using C<bytes>:

    get '/download/:file' => sub {
        send_file(
            params->{file},
            streaming => 1,
            bytes     => 524288, # 512K
        );
    };

The content-type will be set depending on the current MIME types definition
(see C<mime> if you want to define your own).

If your filename does not have an extension, or you need to force a
specific mime type, you can pass it to C<send_file> as follows:

    send_file(params->{file}, content_type => 'image/png');

Also, you can use your aliases or file extension names on
C<content_type>, like this:

    send_file(params->{file}, content_type => 'png');

For files outside your B<public> folder, you can use the C<system_path>
switch. Just bear in mind that its use needs caution as it can be
dangerous.

   send_file('/etc/passwd', system_path => 1);

If you have your data in a scalar variable, C<send_file> can be useful
as well. Pass a reference to that scalar, and C<send_file> will behave
as if there were a file with that contents:

   send_file( \$data, content_type => 'image/png' );

Note that Dancer is unable to guess the content type from the data
contents. Therefore you might need to set the C<content_type>
properly. For this kind of usage an attribute named C<filename> can be
useful.  It is used as the Content-Disposition header, to hint the
browser about the filename it should use.

   send_file( \$data, content_type => 'image/png'
                             filename     => 'onion.png' );

=head2 set

Defines a setting:

    set something => 'value';

You can set more than one value at once:

    set something => 'value', otherthing => 'othervalue';

=head2 setting

Returns the value of a given setting:

    setting('something'); # 'value'

=head2 set_cookie

Creates or updates cookie values:

    get '/some_action' => sub {
        set_cookie name => 'value',
                   expires => (time + 3600),
                   domain  => '.foo.com';
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

You can't store more complex structure than this. All keys in the HashRef
should be Scalars; storing references will not work.

See L<Dancer::Cookie> for further options when creating your cookie.

Note that this method will be eventually deprecated in favor of the
new C<cookie> method.

=head2 session

Provides access to all data stored in the user's session (if any).

It can also be used as a setter to store data in the session:

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

If you need to fetch the session ID being used for any reason:

    my $id = session->id;

In order to be able to use sessions, first  you need to enable session support in
one of the configuration files.  A quick way to do it is to add

    session: "YAML"

to config.yml.

For more details, see L<Dancer::Session>.

=head2 splat

Returns the list of captures made from a route handler with a route pattern
which includes wildcards:

    get '/file/*.*' => sub {
        my ($file, $extension) = splat;
        ...
    };

There is also the extensive splat (A.K.A. "megasplat"), which allows extensive
greedier matching, available using two asterisks. The additional path is broken
down and returned as an ArrayRef:

    get '/entry/*/tags/**' => sub {
        my ( $entry_id, $tags ) = splat;
        my @tags = @{$tags};
    };

This helps with chained actions:

    get '/team/*/**' => sub {
        my ($team) = splat;
        var team => $team;
        pass;
    };

    prefix '/team/*';

    get '/player/*' => sub {
        my ($player) = splat;

        # etc...
    };

    get '/score' => sub {
        return score_for( vars->{'team'} );
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

In that example Dancer will notice that the status has changed, and will
render the response accordingly.

The status keyword receives either a numeric status code or its name in
lower case, with underscores as a separator for blanks. See the list in
L<Dancer::HTTP/"HTTP CODES">.

=head2 template

Returns the response of processing the given template with the given parameters
(and optional settings), wrapping it in the default or specified layout too, if
layouts are in use.

An example of a route handler which returns the result of using template to 
build a response with the current template engine:

    get '/' => sub {
        ...
        return template 'some_view', { token => 'value'};
    };

Note that C<template> simply returns the content, so when you use it in a route
handler, if execution of the route handler should stop at that point, make
sure you use 'return' to ensure your route handler returns the content.

Since template just returns the result of rendering the template, you can also
use it to perform other templating tasks, e.g. generating emails:

    post '/some/route' => sub {
        if (...) {
            email {
                to      => 'someone@example.com',
                from    => 'foo@example.com',
                subject => 'Hello there',
                msg     => template('emails/foo', { name => params->{name} }),
            };

            return template 'message_sent';
        } else {
            return template 'error';
        }
    };

Compatibility notice: C<template> was changed in version 1.3090 to immediately
interrupt execution of a route handler and return the content, as it's typically
used at the end of a route handler to return content.  However, this caused
issues for some people who were using C<template> to generate emails etc, rather
than accessing the template engine directly, so this change has been reverted
in 1.3091.

The first parameter should be a template available in the views directory, the
second one (optional) is a HashRef of tokens to interpolate, and the third
(again optional) is a HashRef of options.

For example, to disable the layout for a specific request:

    get '/' => sub {
        template 'index', {}, { layout => undef };
    };

Or to request a specific layout, of course:

    get '/user' => sub {
        template 'user', {}, { layout => 'user' };
    };

Some tokens are automatically added to your template (C<perl_version>,
C<dancer_version>, C<settings>, C<request>, C<params>, C<vars> and, if
you have sessions enabled, C<session>).  Check
L<Dancer::Template::Abstract> for further details.

=head2 to_dumper ($structure)

Serializes a structure with L<< Data::Dumper >>.

=head2 to_json ($structure, %options)

Serializes a structure to JSON. Can receive optional arguments. Thoses arguments
are valid L<JSON> arguments to change the behaviour of the default
C<JSON::to_json> function.

=head2 to_yaml ($structure)

Serializes a structure to YAML.

=head2 to_xml ($structure, %options)

Serializes a structure to XML. Can receive optional arguments. Thoses arguments
are valid L<XML::Simple> arguments to change the behaviour of the default
C<XML::Simple::XMLout> function.

=head2 true

Constant that returns a true value (1).

=head2 upload

Provides access to file uploads.  Any uploaded file is accessible as a
L<Dancer::Request::Upload> object. You can access all parsed uploads via:

    post '/some/route' => sub {
        my $file = upload('file_input_foo');
        # file is a Dancer::Request::Upload object
    };

If you named multiple inputs of type "file" with the same name, the upload
keyword will return an Array of Dancer::Request::Upload objects:

    post '/some/route' => sub {
        my ($file1, $file2) = upload('files_input');
        # $file1 and $file2 are Dancer::Request::Upload objects
    };

You can also access the raw HashRef of parsed uploads via the current request
object:

    post '/some/route' => sub {
        my $all_uploads = request->uploads;
        # $all_uploads->{'file_input_foo'} is a Dancer::Request::Upload object
        # $all_uploads->{'files_input'} is an ArrayRef of Dancer::Request::Upload objects
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

Returns a reference to a copy of C<%+>, if there are named captures in the route
Regexp.

Named captures are a feature of Perl 5.10, and are not supported in earlier
versions:

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

Provides an accessor for variables shared between filters and route handlers.
Given a key/value pair, it sets a variable:

    hook before sub {
        var foo => 42;
    };

Later, route handlers and other filters will be able to read that variable:

    get '/path' => sub {
        my $foo = var 'foo';
        ...
    };

=head2 vars

Returns the HashRef of all shared variables set during the filter/route
chain with the C<var> keyword:

    get '/path' => sub {
        if (vars->{foo} eq 42) {
            ...
        }
    };

=head2 warning

Logs a warning message through the current logger engine:

    warning "This is a warning";

See L<Dancer::Logger> for details on how to configure where log messages go.

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@cpan.org> and others,
see the AUTHORS file that comes with this distribution for details.

=head1 SOURCE CODE

The source code for this module is hosted on GitHub
L<https://github.com/PerlDancer/Dancer>.  Feel free to fork the repository and
submit pull requests!  (See L<Dancer::Development> for details on how to
contribute).

Also, why not L<watch the repo|https://github.com/PerlDancer/Dancer/toggle_watch>
to keep up to date with the latest upcoming changes?

=head1 GETTING HELP / CONTRIBUTING

The Dancer development team can be found on #dancer on irc.perl.org:
L<irc://irc.perl.org/dancer>

If you don't have an IRC client installed/configured, there is a simple web chat
client at L<http://www.perldancer.org/irc> for you.

There is also a Dancer users mailing list available. Subscribe at:

L<http://lists.preshweb.co.uk/mailman/listinfo/dancer-users>

If you'd like to contribute to the Dancer project, please see
L<http://www.perldancer.org/contribute> for all the ways you can help!

=head1 DEPENDENCIES

The following modules are mandatory (Dancer cannot run without them):

=over 8

=item L<HTTP::Server::Simple::PSGI>

=item L<HTTP::Body>

=item L<LWP>

=item L<MIME::Types>

=item L<URI>

=back

The following modules are optional:

=over 8

=item L<JSON> : needed to use JSON serializer

=item L<Plack> : in order to use PSGI

=item L<Template> : in order to use TT for rendering views

=item L<XML::Simple> and L<XML:SAX> or L<XML:Parser> for XML serialization

=item L<YAML> : needed for configuration file support

=back

=head1 SEE ALSO

Main Dancer web site: L<http://perldancer.org/>.

The concept behind this module comes from the Sinatra ruby project,
see L<http://www.sinatrarb.com/> for details.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
