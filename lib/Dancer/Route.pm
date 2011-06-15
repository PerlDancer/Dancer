package Dancer::Route;
# ABSTRACT: class that represents Dancer routes

=head1 DESCRIPTION

This class represents a route and is used internally by Dancer. A
route contains a path, a method and a coderef to be executed on
matching request, to produce a response.

The route object provides everything needed to store new routes, parse
them and execute matching against incoming requests.

=cut

use strict;
use warnings;
use Carp;
use base 'Dancer::Object';

use Dancer::App;
use Dancer::Logger;
use Dancer::Config 'setting';
use Dancer::Request;
use Dancer::Response;

Dancer::Route->attributes(
    qw(
      app
      method
      pattern
      prefix
      code
      prev
      regexp
      next
      options
      match_data
      )
);

# supported options and aliases
my @_supported_options = Dancer::Request->get_attributes();
my %_options_aliases = (agent => 'user_agent');

=method init

Whenever a route object is created, this method is called to prepare
the object.

=cut
sub init {
    my ($self) = @_;
    $self->{'_compiled_regexp'} = undef;

    if (!$self->pattern) {
        croak "cannot create Dancer::Route without a pattern";
    }

    # If the route is a Regexp, store it directly
    $self->regexp($self->pattern) 
      if ref($self->pattern) eq 'Regexp';

    $self->_check_options();
    $self->app(Dancer::App->current);
    $self->prefix(Dancer::App->current->prefix) if not $self->prefix;
    $self->_init_prefix() if $self->prefix;
    $self->_build_regexp();
    $self->set_previous($self->prev) if $self->prev;

    return $self;
}

=method set_previous

When Dancer parses the route declared by the application, it builds a
chained-list of routes, in their order of declaration.

This method allows to register the previous route of the current one,
in the matching tree of the application.

    $route->set_previous($other_route);

=cut
sub set_previous {
    my ($self, $prev) = @_;
    $self->prev($prev);
    $self->prev->{'next'} = $self;
    return $prev;
}


=method match

Takes a L<Dancer::Request> object and looks if the route matches the
request.  The matching is performed using the HTTP method and route
pattern of the route.  If there is a match, all the params are
processed and saved so the route action can be executed.

    if ($route->match($request)) {
         ...
    }

Note that this method uses the logger engine (core level) to give some
feedback about what it sees and how it matches or not.

=cut
sub match {
    my ($self, $request) = @_;

    my $method = lc($request->method);
    my $path   = $request->path_info;
    my %params;

    Dancer::Logger::core("trying to match `$path' "
          . "against /"
          . $self->{_compiled_regexp}
          . "/");

    my @values = $path =~ $self->{_compiled_regexp};

    # the regex comments are how we know if we captured
    # a splat or a megasplat
    if( my @splat_or_megasplat
            = $self->{_compiled_regexp} =~ /\(\?#((?:mega)?splat)\)/g ) {
        for ( @values ) {
            $_ = [ split '/' => $_ ] if ( shift @splat_or_megasplat ) =~ /megasplat/;
        }
    }

    Dancer::Logger::core("  --> got ".
        map { defined $_ ? $_ : 'undef' } @values)
        if @values;

    # if some named captures found, return captures
    # no warnings is for perl < 5.10
    if (my %captures =
        do { no warnings; %+ }
      )
    {
        Dancer::Logger::core(
            "  --> captures are: " . join(", ", keys(%captures)))
          if keys %captures;
        return $self->_save_match_data($request, {captures => \%captures});
    }

    return unless @values;

    # save the route pattern that matched
    # TODO : as soon as we have proper Dancer::Internal, we should remove
    # that, it's just a quick hack for plugins to access the matching
    # pattern.
    # NOTE: YOU SHOULD NOT USE THAT, OR IF YOU DO, YOU MUST KNOW
    # IT WILL MOVE VERY SOON
    $request->{_route_pattern} = $self->pattern;

    # named tokens
    my @tokens = @{$self->{_params} || []};

    Dancer::Logger::core("  --> named tokens are: @tokens") if @tokens;
    if (@tokens) {
        for (my $i = 0; $i < @tokens; $i++) {
            $params{$tokens[$i]} = $values[$i];
        }
        return $self->_save_match_data($request, \%params);
    }

    elsif ($self->{_should_capture}) {
        return $self->_save_match_data($request, {splat => \@values});
    }

    return $self->_save_match_data($request, {});
}

=method has_options

Boolean that tells if the route object has registered options or not.

=cut
sub has_options {
    my ($self) = @_;
    return keys(%{$self->options}) ? 1 : 0;
}

=method validate_options

Boolean that tells if all the options given are supported or not.

=cut
sub validate_options {
    my ($self, $request) = @_;

    while (my ($option, $value) = each %{$self->options}) {
        $option = $_options_aliases{$option}
          if exists $_options_aliases{$option};
        return 0 if (not $request->$option) || ($request->$option !~ $value);
    }
    return 1;
}

=method run

This method runs the route's action on the given request. It takes
care of doing anything needed to prepare the environement.

It also takes care of passing the baton to the next matching route if
the current route passes, or if it uses C<forward>.

It returns a L<Dancer::Response> object.

=cut
sub run {
    my ($self, $request) = @_;

    my $content  = $self->_execute();
    my $response = Dancer::SharedData->response;

    if ( $response && $response->is_forwarded ) {
        my $new_req = 
            Dancer::Request->forward($request, $response->{forward});
        my $marshalled = Dancer::Handler->handle_request($new_req);

        return Dancer::Response->new(
            encoded => 1,
            status  => $marshalled->[0],
            headers => $marshalled->[1],
            # if the forward failed with 404, marshalled->[2] is not an array, but a GLOB
            content => ref($marshalled->[2]) eq "ARRAY" ? @{ $marshalled->[2] } : $marshalled->[2]
        );
    }

    if ($response && $response->has_passed) {
        $response->pass(0);
        if ($self->next) {
            my $next_route = $self->_find_next_matching_route($request);
            return $next_route->run($request);
        }
        else {
            Dancer::Logger::core('Last matching route passed!');
            return undef;
        }
    }

    # coerce undef content to empty string to
    # prevent warnings
    $content = (defined $content) ? $content : '';

    my $ct =
      ( defined $response && defined $response->content_type )
      ? $response->content_type()
      : setting('content_type');

    my $st = defined $response ? $response->status : 200;

    my $headers = [];
    push @$headers, @{ $response->headers_to_array } if defined $response;

    # content type may have already be set earlier
    # (eg: with send_error)
    push(@$headers, 'Content-Type' => $ct)
      unless grep {/Content-Type/} @$headers;

    return $content if ref($content) eq 'Dancer::Response';
    return Dancer::Response->new(
        status       => $st,
        headers      => $headers,
        content      => $content,
    );
}

=method equals

Boolean that tells if the current route is the same as the one given
as argument. The equality is performed on the internal Regexp of the
route.

=cut
sub equals {
    my ($self, $route) = @_;
    return $self->regexp eq $route->regexp;
}



# privates

sub _is_regexp {
    my ($self) = @_;
    return defined $self->regexp;
}

sub _init_prefix {
    my ($self) = @_;
    my $prefix = $self->prefix;

    if ($self->_is_regexp) {
        my $regexp = $self->regexp;
        if ($regexp !~ /^$prefix/) {
            $self->regexp(qr{${prefix}${regexp}});
        }
    }
    elsif ($self->pattern eq '/') {

        # if pattern is '/', we should match:
        # - /prefix/
        # - /prefix
        # this is done by creating a regex for this case
        my $qpattern = quotemeta( $self->pattern );
        my $qprefix  = quotemeta( $self->prefix );
        my $regex    = qr/^$qprefix(?:$qpattern)?$/;
        $self->{regexp}  = $regex;
        $self->{pattern} = $regex;
    }
    else {
        $self->{pattern} = $prefix . $self->pattern;
    }

    return $prefix;
}

sub _save_match_data {
    my ($self, $request, $match_data) = @_;
    $self->match_data($match_data);
    $request->_set_route_params($match_data);

    return $match_data;
}

sub _build_regexp {
    my ($self) = @_;

    if ($self->_is_regexp) {
        $self->{_compiled_regexp} = $self->regexp;
        $self->{_compiled_regexp} = qr/^$self->{_compiled_regexp}$/;
        $self->{_should_capture} = 1;
    }
    else {
        $self->_build_regexp_from_string($self->pattern);
    }

    return $self->{_compiled_regexp};
}

sub _build_regexp_from_string {
    my ($self, $pattern) = @_;
    my $capture = 0;
    my @params;

    # look for route with params (/hello/:foo)
    if ($pattern =~ /:/) {
        @params = $pattern =~ /:([^\/\.\?]+)/g;
        if (@params) {
            $pattern =~ s/(:[^\/\.\?]+)/\(\[\^\/\]\+\)/g;
            $capture = 1;
        }
    }

    # parse megasplat
    # we use {0,} instead of '*' not to fall in the splat rule
    # same logic for [^\n] instead of '.'
    $capture = 1 if $pattern =~ s!\Q**\E!(?#megasplat)([^\n]+)!g;

    # parse wildcards
    $capture = 1 if $pattern =~ s!\*!(?#splat)([^/]+)!g;

    # escape dots
    $pattern =~ s/\./\\\./g if $pattern =~ /\./;

    # escape slashes
    $pattern =~ s/\//\\\//g;

    $self->{_compiled_regexp} = "^${pattern}\$";
    $self->{_params}          = \@params;
    $self->{_should_capture}  = $capture;

    return $self->{_compiled_regexp};
}

sub _check_options {
    my ($self) = @_;
    return 1 unless defined $self->options;

    for my $opt (keys %{$self->options}) {
        croak "Not a valid option for route matching: `$opt'"
          if not(    (grep {/^$opt$/} @{$_supported_options[0]})
                  || (grep {/^$opt$/} keys(%_options_aliases)));
    }
    return 1;
}

sub _find_next_matching_route {
    my ($self, $request) = @_;
    my $next = $self->next;
    return unless $next;

    return $next if $next->match($request);
    return $next->_find_next_matching_route($request);
}

sub _execute {
    my ($self) = @_;

    if (Dancer::Config::setting('warnings')) {
        my $warning;
        local $SIG{__WARN__} = sub { $warning = $_[0] };
        my $content = $self->code->();
        if ($warning) {
            return Dancer::Error->new(
                code    => 500,
                message => "Warning caught during route execution: $warning",
            )->render;
        }
        return $content;
    }
    else {
        return $self->code->();
    }
}


1;
