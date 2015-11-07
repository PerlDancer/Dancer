package Dancer::Test;
our $AUTHORITY = 'cpan:SUKRIA';
#ABSTRACT: Test helpers to test a Dancer application
$Dancer::Test::VERSION = '1.3202';
# test helpers for Dancer apps

use strict;
use warnings;
use Test::Builder;
use Test::More import => [ '!pass' ];

use Carp;
use HTTP::Headers;
use Scalar::Util 'blessed';

use Dancer ':syntax', ':tests';
use Dancer::App;
use Dancer::Deprecation;
use Dancer::Request;
use Dancer::Request::Upload;
use Dancer::SharedData;
use Dancer::Renderer;
use Dancer::Handler;
use Dancer::Config;
use Dancer::FileUtils qw(open_file);

use base 'Exporter';
use vars '@EXPORT';

@EXPORT = qw(
  route_exists
  route_doesnt_exist

  response_exists
  response_doesnt_exist

  response_status_is
  response_status_isnt

  response_content_is
  response_content_isnt
  response_content_is_deeply
  response_content_like
  response_content_unlike

  response_is_file
  response_headers_are_deeply
  response_headers_include
  response_redirect_location_is

  dancer_response

  read_logs
);

sub import {
    my ($class, %options) = @_;
    $options{appdir} ||= '.';

    # mimic PSGI env
    $ENV{SERVERNAME}        = 'localhost';
    $ENV{HTTP_HOST}         = 'localhost';
    $ENV{SERVER_PORT}       = 80;
    $ENV{'psgi.url_scheme'} = 'http';

    my ($package, $script) = caller;
    $class->export_to_level(1, $class, @EXPORT);

    Dancer::_init_script_dir($options{appdir});
    Dancer::Config->load;

    # set a default session engine for tests
    setting 'session' => 'simple';

    # capture logs for testing
    setting 'logger'  => 'capture';
    setting 'log'     => 'debug';
}

# Route Registry

sub _isa {
    my ( $reference, $classname ) = @_;
    return blessed $reference && $reference->isa($classname);
}

sub _req_to_response {
    my $req = shift;

    # already a response object
    return $req if _isa($req, 'Dancer::Response');

    return dancer_response( ref $req eq 'ARRAY' ? @$req : ( 'GET', $req ) );
}

sub _req_label {
    my $req = shift;

    return _isa($req, 'Dancer::Response') ? 'response object'
         : ref $req eq 'ARRAY'            ? join( ' ', @$req )
         :                                  "GET $req";
}

sub expand_req {
    my $req = shift;
    return ref $req eq 'ARRAY' ? @$req : ( 'GET', $req );
}

sub route_exists {
    my ($req, $test_name) = @_;
    my $tb = Test::Builder->new;

    my ($method, $path) = expand_req($req);
    $test_name ||= "a route exists for $method $path";

    $req = Dancer::Request->new_for_request($method => $path);
    return $tb->ok(defined(Dancer::App->find_route_through_apps($req)), $test_name);
}

sub route_doesnt_exist {
    my ($req, $test_name) = @_;
    my $tb = Test::Builder->new;

    my ($method, $path) = expand_req($req);
    $test_name ||= "no route exists for $method $path";

    $req = Dancer::Request->new_for_request($method => $path);
    return $tb->ok(!defined(Dancer::App->find_route_through_apps($req)), $test_name);
}

# Response status

sub response_exists {
    Dancer::Deprecation->deprecated(
       fatal   => 1,
       feature => 'response_exists',
       reason  => 'Use response_status_isnt and check for status 404.'
    );
}

sub response_doesnt_exist {
    Dancer::Deprecation->deprecated(
       fatal   => 1,
       feature => 'response_doesnt_exist',
       reason  => 'Use response_status_is and check for status 404.',
    );
}

sub response_status_is {
    my ($req, $status, $test_name) = @_;
    $test_name ||= "response status is $status for " . _req_label($req);

    my $response = _req_to_response($req);
    my $tb = Test::Builder->new;
    return $tb->is_eq($response->status, $status, $test_name);
}

sub response_status_isnt {
    my ($req, $status, $test_name) = @_;
    $test_name ||= "response status is not $status for " . _req_label($req);

    my $response = _req_to_response($req);
    my $tb = Test::Builder->new;
    $tb->isnt_eq( $response->{status}, $status, $test_name );
}

# Response content

sub response_content_is {
    my ($req, $matcher, $test_name) = @_;
    $test_name ||= "response content looks good for " . _req_label($req);

    my $response = _req_to_response($req);
    my $tb = Test::Builder->new;
    return $tb->is_eq( $response->{content}, $matcher, $test_name );
}

sub response_content_isnt {
    my ($req, $matcher, $test_name) = @_;
    $test_name ||= "response content looks good for " . _req_label($req);

    my $response = _req_to_response($req);
    my $tb = Test::Builder->new;
    return $tb->isnt_eq( $response->{content}, $matcher, $test_name );
}

sub response_content_like {
    my ($req, $matcher, $test_name) = @_;
    $test_name ||= "response content looks good for " . _req_label($req);

    my $response = _req_to_response($req);
    my $tb = Test::Builder->new;
    return $tb->like( $response->{content}, $matcher, $test_name );
}

sub response_content_unlike {
    my ($req, $matcher, $test_name) = @_;
    $test_name ||= "response content looks good for " , _req_label($req);

    my $response = _req_to_response($req);
    my $tb = Test::Builder->new;
    return $tb->unlike( $response->{content}, $matcher, $test_name );
}

sub response_content_is_deeply {
    my ($req, $matcher, $test_name) = @_;
    $test_name ||= "response content looks good for " . _req_label($req);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $response = _req_to_response($req);
    is_deeply $response->{content}, $matcher, $test_name;
}

sub response_is_file {
    my ($req, $test_name) = @_;
    $test_name ||= "a file is returned for " . _req_label($req);

    my $response = _get_file_response($req);
    my $tb = Test::Builder->new;
    return $tb->ok(defined($response), $test_name);
}

sub response_headers_are_deeply {
    my ($req, $expected, $test_name) = @_;
    $test_name ||= "headers are as expected for " . _req_label($req);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $response = _req_to_response($req);

    is_deeply(
        _sort_headers( $response->headers_to_array ),
        _sort_headers( $expected ),
        $test_name
    );
}

# Sort arrayref of headers (turn it into a list of arrayrefs, sort by the header
# & value, then turn it back into an arrayref)
sub _sort_headers {
    my @originalheaders = @{ shift() }; # take a copy we can modify
    my @headerpairs;
    while (my ($header, $value) = splice @originalheaders, 0, 2) {
        push @headerpairs, [ $header, $value ];
    }

    # We have an array of arrayrefs holding header => value pairs; sort them by
    # header then value, and return them flattened back into an arrayref
    return [
        map  { @$_ }
        sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] }
        @headerpairs
    ];
}


sub response_headers_include {
    my ($req, $expected, $test_name) = @_;
    $test_name ||= "headers include expected data for " . _req_label($req);
    my $tb = Test::Builder->new;

    my $response = _req_to_response($req);
    return $tb->ok(_include_in_headers($response->headers_to_array, $expected), $test_name);
}

sub response_redirect_location_is {
    my ($req, $expected, $test_name) = @_;
    $test_name ||= "redirect location looks good for " . _req_label($req);
    my $tb = Test::Builder->new;

    my $response = _req_to_response($req);
    return  $tb->is_eq($response->header('location'), $expected, $test_name);
}


# make sure the given header sublist is included in the full headers array
sub _include_in_headers {
    my ($full_headers, $expected_subset) = @_;

    # walk through all the expected header pairs, make sure
    # they exist with the same value in the full_headers list
    # return false as soon as one is not.
    for (my $i=0; $i<scalar(@$expected_subset); $i+=2) {
        my ($name, $value) = ($expected_subset->[$i], $expected_subset->[$i + 1]);
        return 0
          unless _check_header($full_headers, $name, $value);
    }

    # we've found all the expected pairs in the $full_headers list
    return 1;
}

sub _check_header {
    my ($headers, $key, $value) = @_;
    for (my $i=0; $i<scalar(@$headers); $i+=2) {
        my ($name, $val) = ($headers->[$i], $headers->[$i + 1]);
        return 1 if $name eq $key && $value eq $val;
    }
    return 0;
}

sub dancer_response {
    my ($method, $path, $args) = @_;
    $args ||= {};
    my $extra_env = {};

    if ($method =~ /^(?:PUT|POST)$/) {

        my ($content, $content_type);

        if ( $args->{body} and $args->{files} ) {
            # XXX: When fixing this, update this method's POD
            croak 'dancer_response() does not support both body and files';
        }
        elsif ( $args->{body} ) {
            $content      = $args->{body};
            $content_type = $args->{content_type}
                || 'text/plain';

            # coerce hashref into an url-encoded string
            if ( ref($content) && ( ref($content) eq 'HASH' ) ) {
                my @tokens;
                while ( my ( $name, $value ) = each %{$content} ) {
                    $name  = _url_encode($name);
                    $value = _url_encode($value);
                    push @tokens, "${name}=${value}";
                }
                $content = join( '&', @tokens );
                $content_type = 'application/x-www-form-urlencoded';
            }
        }
        elsif ( $args->{files} ) {
            $content_type = 'multipart/form-data; boundary=----BOUNDARY';
            foreach my $file (@{$args->{files}}){
                $file->{content_type} ||= 'text/plain';
                $content .= qq/------BOUNDARY\r\n/;
                $content .= qq/Content-Disposition: form-data; name="$file->{name}"; filename="$file->{filename}"\r\n/;
                $content .= qq/Content-Type: $file->{content_type}\r\n\r\n/;
                if ( $file->{data} ) {
                    $content .= $file->{data};
                } else {
                    open my $fh, '<', $file->{filename};
                    if ( -B $file->{filename} ) {
                        binmode $fh;
                    }
                    while (<$fh>) {
                        $content .= $_;
                    }
                }
                $content .= "\r\n";
            }
            $content .= "------BOUNDARY";
        }

        my $l = 0;
        $l = length $content if defined $content;
        open my $in, '<', \$content;
        $extra_env->{'CONTENT_LENGTH'} = $l;
        $extra_env->{'CONTENT_TYPE'}   = $content_type || "";
        $extra_env->{'psgi.input'}     = $in;
    }

    my ($params, $body, $headers) = @$args{qw(params body headers)};

    $headers = HTTP::Headers->new(@{$headers||[]})
        unless _isa($headers, "HTTP::Headers");

    if ($headers->header('Content-Type')) {
        $extra_env->{'CONTENT_TYPE'} = $headers->header('Content-Type');
    }

    # handle all the keys of Request::_build_request_env():
    for my $key (qw( user_agent host accept_language accept_charset
        accept_encoding keep_alive connection accept accept_type referer
        x_requested_with )) {
        my $k = sprintf("HTTP_%s", uc $key);
        $extra_env->{$k} = $headers->{$key}
            if exists $headers->{$key};
    }

    # fake the REQUEST_URI
    # TODO deal with the params
    unless( $extra_env->{REQUEST_URI} ) {
        $extra_env->{REQUEST_URI} = $path;
        if ( $method eq 'GET' and $params ) {
            $extra_env->{REQUEST_URI} .=
                '?' . join '&', map { join '=', $_, $params->{$_} } 
                                    sort keys %$params;
        }
    }

    my $request = Dancer::Request->new_for_request(
        $method => $path,
        $params, $body, $headers, $extra_env
    );

    # first, reset the current state
    Dancer::SharedData->reset_all();

    # then store the request
    Dancer::SharedData->request($request);

    # XXX this is a hack!!
    $request = Dancer::Serializer->process_request($request)
      if Dancer::App->current->setting('serializer');

    my $get_action = Dancer::Handler::render_request($request);
    my $response = Dancer::SharedData->response();

    $response->content('') if $method eq 'HEAD';
    Dancer::SharedData->reset_response();
    return $response if $get_action;
    (defined $response && $response->exists) ? return $response : return undef;
}

# private

sub _url_encode {
    my $string = shift;
    $string =~ s/([\W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
    return $string;
}

sub _get_file_response {
    my ($req) = @_;

    my ($method, $path, $params) = expand_req($req);
    my $request = Dancer::Request->new_for_request($method => $path, $params);
    Dancer::SharedData->request($request);
    return Dancer::Renderer::get_file_response();
}

sub _get_handler_response {
    my ($req) = @_;
    my ($method, $path, $params) = expand_req($req);
    my $request = Dancer::Request->new_for_request($method => $path, $params);
    return Dancer::Handler->handle_request($request);
}

sub read_logs {
    return Dancer::Logger::Capture->trap->read;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Test - Test helpers to test a Dancer application

=head1 VERSION

version 1.3202

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Test::More tests => 2;

    use MyWebApp;
    use Dancer::Test;

    response_status_is [GET => '/'], 200, "GET / is found";
    response_content_like [GET => '/'], qr/hello, world/, "content looks good for /";

=head1 DESCRIPTION

This module provides test helpers for testing Dancer apps.

Be careful, the module loading order in the example above is very important.
Make sure to use C<Dancer::Test> B<after> importing the application package
otherwise your appdir will be automatically set to C<lib> and your test script
won't be able to find views, conffiles and other application content.

For all test methods, the first argument can be either an
array ref of the method and route, or a scalar containing the
route (in which case the method is assumed to be C<GET>), or
a L<Dancer::Response> object.

    # all 3 are equivalent
    response_status_is [ GET => '/' ], 200, 'GET / status is ok';

    response_status_is '/', 200, 'GET / status is ok';

    my $resp = dancer_response GET => '/';
    response_status_is $resp => 200, 'GET / status is ok';

=head1 METHODS

=head2 route_exists([$method, $path], $test_name)

Asserts that the given request matches a route handler in Dancer's
registry.

    route_exists [GET => '/'], "GET / is handled";

=head2 route_doesnt_exist([$method, $path], $test_name)

Asserts that the given request does not match any route handler
in Dancer's registry.

    route_doesnt_exist [GET => '/bogus_path'], "GET /bogus_path is not handled";

=head2 response_exists([$method, $path], $test_name)

Deprecated - Use response_status_isnt and check for status 404.

Asserts that a response is found for the given request (note that even though
a route for that path might not exist, a response can be found during request
processing, because of filters).

    response_exists [GET => '/path_that_gets_redirected_to_home'],
        "response found for unknown path";

=head2 response_doesnt_exist([$method, $path], $test_name)

Deprecated - Use response_status_is and check for status 404.

Asserts that no response is found when processing the given request.

    response_doesnt_exist [GET => '/unknown_path'],
        "response not found for unknown path";

=head2 response_status_is([$method, $path], $status, $test_name)

Asserts that Dancer's response for the given request has a status equal to the
one given.

    response_status_is [GET => '/'], 200, "response for GET / is 200";

=head2 response_status_isnt([$method, $path], $status, $test_name)

Asserts that the status of Dancer's response is not equal to the
one given.

    response_status_isnt [GET => '/'], 404, "response for GET / is not a 404";

=head2 response_content_is([$method, $path], $expected, $test_name)

Asserts that the response content is equal to the C<$expected> string.

    response_content_is [GET => '/'], "Hello, World",
        "got expected response content for GET /";

=head2 response_content_isnt([$method, $path], $not_expected, $test_name)

Asserts that the response content is not equal to the C<$not_expected> string.

    response_content_isnt [GET => '/'], "Hello, World",
        "got expected response content for GET /";

=head2 response_content_is_deeply([$method, $path], $expected_struct, $test_name)

Similar to response_content_is(), except that if response content and
$expected_struct are references, it does a deep comparison walking each data
structure to see if they are equivalent.

If the two structures are different, it will display the place where they start
differing.

    response_content_is_deeply [GET => '/complex_struct'],
        { foo => 42, bar => 24},
        "got expected response structure for GET /complex_struct";

=head2 response_content_like([$method, $path], $regexp, $test_name)

Asserts that the response content for the given request matches the regexp
given.

    response_content_like [GET => '/'], qr/Hello, World/,
        "response content looks good for GET /";

=head2 response_content_unlike([$method, $path], $regexp, $test_name)

Asserts that the response content for the given request does not match the regexp
given.

    response_content_unlike [GET => '/'], qr/Page not found/,
        "response content looks good for GET /";

=head2 response_headers_are_deeply([$method, $path], $expected, $test_name)

Asserts that the response headers data structure equals the one given.

    response_headers_are_deeply [GET => '/'], [ 'X-Powered-By' => 'Dancer 1.150' ];

=head2 response_headers_include([$method, $path], $expected, $test_name)

Asserts that the response headers data structure includes some of the defined ones.

    response_headers_include [GET => '/'], [ 'Content-Type' => 'text/plain' ];

=head2 response_redirect_location_is([$method, $path], $expected, $test_name)

Asserts that the location header send with a 302 redirect equals to the C<$expected>
location.

    response_redirect_location_is [GET => '/'], 'http://localhost/index.html';

=head2 dancer_response($method, $path, { params => $params, body => $body, headers => $headers, files => [{filename => '/path/to/file', name => 'my_file'}] })

Returns a L<< Dancer::Response >> object for the given request.

Only $method and $path are required.

$params is a hashref, $body can be a string or a hashref and $headers can be an arrayref or
a L<< HTTP::Headers >> object, $files is an arrayref of hashref, containing some files to upload.

$params always populates the query string, even for POST requests.  $body
always populates the request body.

Currently, Dancer::Test cannot cope with both I<< body >> and I<< files >>
passed in the same call.

A good reason to use this function is for testing POST requests. Since POST
requests may not be idempotent, it is necessary to capture the content and
status in one shot. Calling the response_status_is and response_content_is
functions in succession would make two requests, each of which could alter the
state of the application and cause Schrodinger's cat to die.

    my $response = dancer_response POST => '/widgets';
    is $response->{status}, 202, "response for POST /widgets is 202";
    is $response->{content}, "Widget #1 has been scheduled for creation",
        "response content looks good for first POST /widgets";

    $response = dancer_response POST => '/widgets';
    is $response->{status}, 202, "response for POST /widgets is 202";
    is $response->{content}, "Widget #2 has been scheduled for creation",
        "response content looks good for second POST /widgets";

It's possible to test file uploads:

    post '/upload' => sub { return upload('image')->content };

    $response = dancer_response(POST => '/upload', {files => [{name => 'image', filename => '/path/to/image.jpg'}]});

In addition, you can supply the file contents as the C<data> key:

    my $data  = 'A test string that will pretend to be file contents.';
    $response = dancer_response(POST => '/upload', {
        files => [{name => 'test', filename => "filename.ext", data => $data}]
    });

=head2 read_logs

    my $logs = read_logs;

Returns an array ref of all log messages issued by the app since the
last call to C<read_logs>.

For example:

    warning "Danger!  Warning!";
    debug   "I like pie.";

    is_deeply read_logs, [
        { level => "warning", message => "Danger!  Warning!" },
        { level => "debug",   message => "I like pie.", }
    ];

    error "Put out the light.";

    is_deeply read_logs, [
        { level => "error", message => "Put out the light." },
    ];

See L<Dancer::Logger::Capture> for more details.

=head1 LICENSE

This module is free software and is distributed under the same terms as Perl
itself.

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@sukria.net>

=head1 SEE ALSO

L<Test::More>

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
